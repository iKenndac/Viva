//
//  VivaPlaybackManager.m
//  Viva
//
//  Created by Daniel Kennett on 3/30/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaPlaybackManager.h"
#import "Constants.h"
#import "SPArrayExtensions.h"
#import "LastFMController.h"
#import "LocalFilesController.h"
#import "VivaLocalFileDecoder.h"
#import "VivaTrackExtensions.h"
#import <AudioToolbox/AudioToolbox.h>

@interface VivaPlaybackManager  ()

@property (strong, readwrite) SPCircularBuffer *audioBuffer;
@property (strong, readwrite) id <VivaPlaybackContext> playbackContext;
@property (readwrite, strong) id <VivaTrackContainer> currentTrackContainer;
@property (readwrite, strong) SPSession *session;
@property (readwrite, strong) VivaLocalFileDecoder *localFileDecoder;
@property (readwrite, strong) id <SPSessionPlaybackProvider> currentPlaybackProvider;

-(BOOL)playTrackContainerInCurrentContext:(id <VivaTrackContainer>)newTrack error:(NSError **)error;

-(id <VivaTrackContainer>)nextTrackContainerInCurrentContext;
-(id <VivaTrackContainer>)previousTrackContainerInCurrentContext;

// Shuffle

-(void)addTrackContainerToPastShuffleHistory:(id <VivaTrackContainer>)container;
-(void)addTrackContainerToFutureShuffleHistory:(id <VivaTrackContainer>)container;
-(void)resetShuffledPool;
-(void)resetShuffleHistory;
-(id <VivaTrackContainer>)randomAvailableTrackContainerInCurrentContext;
-(void)addTrackContainerToShufflePool:(id <VivaTrackContainer>)track;

// Last.fm

-(void)scrobbleTrackStopped:(SPTrack *)track atPosition:(NSTimeInterval)position;

// Core Audio
-(BOOL)setupCoreAudioWithAudioFormat:(const sp_audioformat *)audioFormat error:(NSError **)err;
-(void)teardownCoreAudio;
-(void)startAudioQueue;
-(void)stopAudioQueue;
-(void)applyVolumeToAudioUnit:(double)vol;
-(void)applyBandsToAudioUnit;

static OSStatus VivaAudioUnitRenderDelegateCallback(void *inRefCon,
                                                    AudioUnitRenderActionFlags *ioActionFlags,
                                                    const AudioTimeStamp *inTimeStamp,
                                                    UInt32 inBusNumber,
                                                    UInt32 inNumberFrames,
                                                    AudioBufferList *ioData);

//vDSP 

static void performAcceleratedFastFourierTransformWithWaveform(VivaPlaybackManager *manager, short *waveformArray, vDSP_Length sampleCount, double *leftDestination, double *rightDestination);
@property (readwrite, strong) NSArray *leftLevels;
@property (readwrite, strong) NSArray *rightLevels;

@end

#define kMaximumBytesInBuffer 44100 * 2 * 2 * 0.5 // 0.5 Second @ 44.1kHz, 16bit per channel, stereo

static NSUInteger const fftMagnitudeExponent = 4; // Must be power of two

@implementation VivaPlaybackManager {
	
	BOOL hasPreCachedNextTrack;
	NSMethodSignature *incrementTrackPositionMethodSignature;
	NSInvocation *incrementTrackPositionInvocation;
	
    NSMutableArray *shuffledPool;
    NSMutableArray *shufflePastHistory;
    NSMutableArray *shuffleFutureHistory;
    
    AUGraph audioProcessingGraph;
	AudioUnit outputUnit;
	AudioUnit eqUnit;
    
	// vDSP
	FFTSetupD fft_weights;
	double *leftChannelMagnitudes;
	double *rightChannelMagnitudes;
}

- (id)initWithPlaybackSession:(SPSession *)aSession {
    self = [super init];
    if (self) {
        // Initialization code here.
        
        shuffledPool = [NSMutableArray new];
        shufflePastHistory = [[NSMutableArray alloc] initWithCapacity:kShuffleHistoryLength];
        shuffleFutureHistory = [[NSMutableArray alloc] initWithCapacity:kShuffleHistoryLength];
		
		SEL incrementTrackPositionSelector = @selector(incrementTrackPositionWithFrameCount:);
		incrementTrackPositionMethodSignature = [VivaPlaybackManager instanceMethodSignatureForSelector:incrementTrackPositionSelector];
		incrementTrackPositionInvocation = [NSInvocation invocationWithMethodSignature:incrementTrackPositionMethodSignature];
		[incrementTrackPositionInvocation setSelector:incrementTrackPositionSelector];
		[incrementTrackPositionInvocation setTarget:self];
		
		self.volume = 1.0;
		
		self.session = aSession;
		self.session.playbackDelegate = self;
		self.localFileDecoder = [[VivaLocalFileDecoder alloc] init];
		self.localFileDecoder.playbackDelegate = self;
		
		EQPresetController *eqController = [EQPresetController sharedInstance];
		
		for (EQPreset *preset in [[[eqController.builtInPresets
								   arrayByAddingObjectsFromArray:eqController.customPresets]
								  arrayByAddingObject:eqController.blankPreset]
								  arrayByAddingObject:eqController.unnamedCustomPreset]) {
			if ([preset.name isEqualToString:[[NSUserDefaults standardUserDefaults] valueForKey:kCurrentEQPresetNameUserDefaultsKey]]) {
				self.eqBands = preset;
				break;
			}
		}
		
		if (self.eqBands == nil)
			self.eqBands = eqController.blankPreset;
		
		self.audioBuffer = [[SPCircularBuffer alloc] initWithMaximumLength:kMaximumBytesInBuffer];
        
        self.loopPlayback = [[NSUserDefaults standardUserDefaults] boolForKey:kLoopPlaybackDefaultsKey];
        self.shufflePlayback = [[NSUserDefaults standardUserDefaults] boolForKey:kShufflePlaybackDefaultsKey];
        		
        [self addObserver:self
               forKeyPath:@"currentPlaybackProvider.playing"
                  options:0
                  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"currentTrackContainer"
				  options:NSKeyValueObservingOptionOld
				  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"currentTrackPosition"
				  options:0
				  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"playbackContext"
				  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
				  context:nil];
        
        [self addObserver:self
               forKeyPath:@"volume"
                  options:0
                  context:nil];
        
        [self addObserver:self
               forKeyPath:@"loopPlayback"
                  options:0
                  context:nil];

        [self addObserver:self
               forKeyPath:@"shufflePlayback"
                  options:0
                  context:nil];
		
		[self addObserver:self
               forKeyPath:@"eqBands"
                  options:0
                  context:nil];

		// Playback
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(playTrackFromUserAction:)
													 name:kTrackShouldBePlayedNotification
												   object:nil];

		/* Setup FFT weights (twiddle factors) */
		fft_weights = vDSP_create_fftsetupD(fftMagnitudeExponent, kFFTRadix2);
		
        leftChannelMagnitudes = (double *)malloc(exp2(fftMagnitudeExponent) * sizeof(double));
        rightChannelMagnitudes = (double *)malloc(exp2(fftMagnitudeExponent) * sizeof(double));

		
    }
    
    return self;
}

@synthesize audioBuffer;
@synthesize playbackContext;
@synthesize currentTrackContainer;
@synthesize session;
@synthesize currentPlaybackProvider;
@synthesize currentTrackPosition;
@synthesize volume;
@synthesize loopPlayback;
@synthesize shufflePlayback;
@synthesize dataSource;
@synthesize localFileDecoder;
@synthesize delegate;

@synthesize leftLevels;
@synthesize rightLevels;

@synthesize eqBands;

+(NSSet *)keyPathsForValuesAffectingCurrentTrack {
	return [NSSet setWithObjects:@"currentTrackContainer.track", nil];
}

-(SPTrack *)currentTrack {
	return self.currentTrackContainer.track;
}

+(NSSet *)keyPathsForValuesAffectingCanSkipToNextTrack {
	return [NSSet setWithObjects:@"loopPlayback", @"currentTrack", @"playbackContext.trackContainersForPlayback", nil];
}

-(BOOL)canSkipToNextTrack {
	return (self.loopPlayback || 
			[self.playbackContext.trackContainersForPlayback indexOfObject:self.currentTrackContainer] != [self.playbackContext.trackContainersForPlayback count] - 1);			
}

+(NSSet *)keyPathsForValuesAffectingCanSkipToPreviousTrack {
	return [NSSet setWithObjects:@"loopPlayback", @"currentTrack", @"playbackContext.trackContainersForPlayback", nil];
}

-(BOOL)canSkipToPreviousTrack {
	return (self.loopPlayback || 
			[self.playbackContext.trackContainersForPlayback indexOfObject:self.currentTrack] != 0);			
}

+(NSSet *)keyPathsForValuesAffectingPlayPauseToggleMenuText {
	return [NSSet setWithObject:@"currentPlaybackProvider.playing"];
}

-(NSString *)playPauseToggleMenuText {
	return self.currentPlaybackProvider.isPlaying ? @"Pause" : @"Play";
}

#pragma mark -
#pragma mark Playback Control

-(void)playTrackFromUserAction:(NSNotification *)aNotification {
	
	if (self.currentTrackContainer != nil)
		[self scrobbleTrackStopped:self.currentTrackContainer.track atPosition:self.currentTrackPosition];
	
	// User double-clicked, so reset everything and start again.
	self.currentPlaybackProvider.playing = NO;
    self.currentTrackContainer = nil;
	[self.currentPlaybackProvider unloadPlayback];
	[self teardownCoreAudio];
	[self resetShuffledPool];
	[self.audioBuffer clear];
    
	if (![[aNotification object] conformsToProtocol:@protocol(VivaPlaybackContext)]) {
        id <VivaPlaybackContext> context = nil;
        
        if (![self.dataSource playbackManager:self requiresContextForContextlessPlayRequest:&context] || context == nil)
            return;
        
        self.playbackContext = context;
    } else {
        self.playbackContext = [aNotification object];
    }
    
	id <VivaTrackContainer> container = [[aNotification userInfo] valueForKey:kPlaybackInitialTrackContainerKey];
    
    if (container == nil)
        container = [self nextTrackContainerInCurrentContext];
    
    if (container == nil && self.playbackContext.trackContainersForPlayback.count > 0) {
        
        for (NSUInteger containerIndex = 0; containerIndex < self.playbackContext.trackContainersForPlayback.count; containerIndex++) {
            id <VivaTrackContainer> potentialContainer = [self.playbackContext.trackContainersForPlayback objectAtIndex:containerIndex];
            if (potentialContainer.track.availability == SP_TRACK_AVAILABILITY_AVAILABLE || potentialContainer.track.localFile != nil) {
                container = potentialContainer;
                break;
            }
        }
    }
        
    
    NSError *error = nil;
    if (container && [self playTrackContainerInCurrentContext:container error:&error]) {
        self.currentPlaybackProvider.playing = YES;
    } else {
		
		NSMutableDictionary *errorDict = [NSMutableDictionary dictionary];
		[errorDict setValue:container forKey:kVivaTrackContainerKey];
		if (error) [errorDict setValue:error forKey:NSUnderlyingErrorKey];
		
		[self.delegate playbackManager:self
			 didEncounterPlaybackError:[NSError errorWithDomain:kVivaPlaybackManagerErrorDomain
														   code:kVivaTrackFailedToPlayErrorCode
													   userInfo:errorDict]];
	}
}

-(BOOL)playTrackContainerInCurrentContext:(id <VivaTrackContainer>)newTrack error:(NSError **)error {
	
	// Don't clear out the audio buffer just in case we can manage gapless playback.
    self.currentTrackPosition = 0.0;    
    
	if (newTrack.track.localFile != nil) {
		self.currentPlaybackProvider = self.localFileDecoder;
	} else {
		self.currentPlaybackProvider = self.session;
	}
	
	BOOL isPlaying = [self.currentPlaybackProvider playTrack:newTrack.track error:error];
    
    if (isPlaying && self.shufflePlayback) {
        [self addTrackContainerToShufflePool:currentTrackContainer];
    }
    
    if (isPlaying) self.currentTrackContainer = newTrack;
	
    return isPlaying;
}
	
-(void)seekToTrackPosition:(NSTimeInterval)newPosition {
	if (newPosition <= self.currentTrack.duration) {
		[self.currentPlaybackProvider seekPlaybackToOffset:newPosition];
		self.currentTrackPosition = newPosition;
	}	
}

-(id <VivaTrackContainer>)nextTrackContainerInCurrentContext {
    
    if (self.shufflePlayback) {
        id <VivaTrackContainer> track = nil;
        
        if (shuffleFutureHistory.count > 0) {
            track = [shuffleFutureHistory lastObject];
            [shuffleFutureHistory removeLastObject];
        } else {
            track = [self randomAvailableTrackContainerInCurrentContext];
        }
        
        if (track == nil && self.loopPlayback) {
            [self resetShuffledPool];
            track = [self randomAvailableTrackContainerInCurrentContext];
        }
        return track;
    }
	
	NSUInteger currentTrackIndex = [self.playbackContext.trackContainersForPlayback indexOfObject:self.currentTrackContainer];
	
	if (currentTrackIndex == NSNotFound ||
		(currentTrackIndex == [self.playbackContext.trackContainersForPlayback count] - 1 && !self.loopPlayback)) {
		return nil;
        
	} else {
		
        NSInteger newTrackIndex = 0;
        
        if (currentTrackIndex != [self.playbackContext.trackContainersForPlayback count] - 1)
            newTrackIndex = currentTrackIndex + 1;
        
        id <VivaTrackContainer> nextTrack = [self.playbackContext.trackContainersForPlayback objectAtIndex:newTrackIndex];
        
        while (nextTrack.track.availability != SP_TRACK_AVAILABILITY_AVAILABLE && nextTrack.track.localFile == nil) {
            
            newTrackIndex++;
            if (newTrackIndex >= self.playbackContext.trackContainersForPlayback.count) {
                nextTrack = nil;
                break;
            }
            nextTrack = [self.playbackContext.trackContainersForPlayback objectAtIndex:newTrackIndex];
        }
        return nextTrack;
	}
}

-(void)skipToNextTrackInCurrentContext:(BOOL)clearExistingAudioBuffers {
	
	if (self.currentTrackContainer != nil)
		[self scrobbleTrackStopped:self.currentTrackContainer.track atPosition:self.currentTrackPosition];
	
	BOOL wasPlaying = self.currentPlaybackProvider.playing;
	
	if (clearExistingAudioBuffers) {
		[self.currentPlaybackProvider setPlaying:NO];
		[self.currentPlaybackProvider unloadPlayback];
		[self teardownCoreAudio];
		
		[self.audioBuffer clear];
	}
	
	id <VivaTrackContainer> nextContainer = [self nextTrackContainerInCurrentContext];
	
    if (self.shufflePlayback && self.currentTrackContainer != nil)
        [self addTrackContainerToPastShuffleHistory:self.currentTrackContainer];
    
    NSError *error = nil;
	if (nextContainer != nil && [self playTrackContainerInCurrentContext:nextContainer error:&error]) {
		self.currentPlaybackProvider.playing = wasPlaying;
	} else {
		self.currentTrackContainer = nil;
		[self teardownCoreAudio];
		self.currentTrackPosition = 0;
        if (error)
            NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
	}
}

-(id <VivaTrackContainer>)previousTrackContainerInCurrentContext {
	
    if (self.shufflePlayback) {
        id <VivaTrackContainer> track = nil;
        
        if (shufflePastHistory.count > 0) {
            track = [shufflePastHistory lastObject];
            [shufflePastHistory removeLastObject];
        } else {
            track = [self randomAvailableTrackContainerInCurrentContext];
        }
        
        if (track == nil && self.loopPlayback) {
            [self resetShuffledPool];
            track = [self randomAvailableTrackContainerInCurrentContext];
        }
        return track;
    }

    
	NSUInteger currentTrackIndex = [self.playbackContext.trackContainersForPlayback indexOfObject:self.currentTrackContainer];
	
	if (currentTrackIndex == NSNotFound ||
		(currentTrackIndex == 0 && !self.loopPlayback)) {
		return nil;
        
        
    } else {
        
        NSInteger newTrackIndex = [self.playbackContext.trackContainersForPlayback count] - 1;
        
        if (currentTrackIndex != 0)
            newTrackIndex = currentTrackIndex - 1;
        
        id <VivaTrackContainer> previousTrack = [self.playbackContext.trackContainersForPlayback objectAtIndex:newTrackIndex];
        
        while (previousTrack.track.availability != SP_TRACK_AVAILABILITY_AVAILABLE && previousTrack.track.localFile == nil) {
            
            newTrackIndex--;
            if (newTrackIndex < 0) {
                previousTrack = nil;
                break;
            }
            previousTrack = [self.playbackContext.trackContainersForPlayback objectAtIndex:newTrackIndex];
        }
        return previousTrack;
    }
}

-(void)skipToPreviousTrackInCurrentContext:(BOOL)clearExistingAudioBuffers {
	
	if (self.currentTrackContainer != nil)
		[self scrobbleTrackStopped:self.currentTrackContainer.track atPosition:self.currentTrackPosition];
	
	BOOL wasPlaying = self.currentPlaybackProvider.playing;
	
	if (clearExistingAudioBuffers) {
		[self.currentPlaybackProvider setPlaying:NO];
		[self.currentPlaybackProvider unloadPlayback];
		[self teardownCoreAudio];
		
		[self.audioBuffer clear];
	}
	
	id <VivaTrackContainer> previousContainer = [self previousTrackContainerInCurrentContext];
	
    if (self.shufflePlayback && self.currentTrackContainer != nil)
        [self addTrackContainerToFutureShuffleHistory:self.currentTrackContainer];

    NSError *error = nil;
	if (previousContainer != nil && [self playTrackContainerInCurrentContext:previousContainer error:&error]) {
		self.currentPlaybackProvider.playing = wasPlaying;
	} else {
		self.currentTrackContainer = nil;
		[self teardownCoreAudio];
		self.currentTrackPosition = 0;
        if (error)
            NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
	}
}

#pragma mark -
#pragma mark Managing Shuffle

-(void)addTrackContainerToPastShuffleHistory:(id <VivaTrackContainer>)container {
    if (!container) return;
    if (shufflePastHistory.count >= kShuffleHistoryLength)
        [shufflePastHistory removeObjectAtIndex:0];
    
    [shufflePastHistory addObject:container];
}

-(void)addTrackContainerToFutureShuffleHistory:(id <VivaTrackContainer>)container {
    if (!container) return;
    if (shuffleFutureHistory.count >= kShuffleHistoryLength)
        [shuffleFutureHistory removeObjectAtIndex:0];
    
    [shuffleFutureHistory addObject:container];
}

-(void)resetShuffledPool {
    [shuffledPool removeAllObjects];
}

-(void)resetShuffleHistory {
    [shuffleFutureHistory removeAllObjects];
    [shufflePastHistory removeAllObjects];
}

-(id <VivaTrackContainer>)randomAvailableTrackContainerInCurrentContext {
    
    NSMutableArray *tracks = [[[self playbackContext] trackContainersForPlayback] mutableCopy];
    [tracks removeObjectsInArray:shuffledPool];
    
    NSMutableArray *unavailableTracks = [NSMutableArray array];
    
    for (id <VivaTrackContainer> trackContainer in tracks) {
        if (trackContainer.track.availability != SP_TRACK_AVAILABILITY_AVAILABLE &&
			trackContainer.track.localFile == nil) {
            [unavailableTracks addObject:trackContainer];
			// If a track isn't available, pretend we've played it so we don't have to check the track
			// every time.
			[self addTrackContainerToShufflePool:trackContainer];
		}
    }
    
    [tracks removeObjectsInArray:unavailableTracks];

    if (tracks.count == 0)
        return nil;
    
    id <VivaTrackContainer> trackContainer = [tracks randomObject];
    [self addTrackContainerToShufflePool:trackContainer];
    return trackContainer;
}

-(void)addTrackContainerToShufflePool:(id <VivaTrackContainer>)track {
    if (!track) return;
    [shuffledPool addObject:track];
}

#pragma mark -
#pragma mark Last.fm

-(void)scrobbleTrackStopped:(SPTrack *)track atPosition:(NSTimeInterval)position {
	if (track != nil && [[NSUserDefaults standardUserDefaults] boolForKey:kScrobblePlaybackToLastFMUserDefaultsKey])
		[[LastFMController sharedInstance] notifyTrackPlaybackDidEnd:track atPosition:position];	
}

#pragma mark -
#pragma mark Playback Callbacks

-(void)sessionDidLosePlayToken:(SPSession *)aSession {
	[self.delegate playbackManager:self
		 didEncounterPlaybackError:[NSError errorWithDomain:kVivaPlaybackManagerErrorDomain
													   code:kVivaTrackTokenLostErrorCode
												   userInfo:nil]];
}

-(void)sessionDidEndPlayback:(SPSession *)aSession {
	// Not routing this through to the main thread causes odd locks and crashes.
	[self performSelectorOnMainThread:@selector(sessionDidEndPlaybackOnMainThread:)
						   withObject:aSession
						waitUntilDone:YES];
}

-(void)sessionDidEndPlaybackOnMainThread:(SPSession *)aSession {
	[self skipToNextTrackInCurrentContext:NO];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
	if ([keyPath isEqualToString:@"eqBands"]) {
		[self applyBandsToAudioUnit];
		[[NSUserDefaults standardUserDefaults] setValue:self.eqBands.name
												 forKey:kCurrentEQPresetNameUserDefaultsKey];
		
	} else if ([keyPath isEqualToString:@"currentPlaybackProvider.playing"]) {
        
        if (self.currentPlaybackProvider.playing) {
            [self startAudioQueue];
        } else {
            [self stopAudioQueue];
        }
		
		if (self.currentTrackContainer != nil && [[NSUserDefaults standardUserDefaults] boolForKey:kScrobblePlaybackToLastFMUserDefaultsKey]) {
			if (self.currentPlaybackProvider.playing)
				[[LastFMController sharedInstance] notifyPlaybackDidStart:self.currentTrackContainer.track];
			else
				[[LastFMController sharedInstance] notifyPlaybackDidPause:self.currentTrackContainer.track];
		}
		
		if ([self.playbackContext respondsToSelector:@selector(setPlayingTrackContainer:isPlaying:)]) {
			[self.playbackContext setPlayingTrackContainer:self.currentTrackContainer isPlaying:self.currentPlaybackProvider.isPlaying];
		}
		
	} else if ([keyPath isEqualToString:@"currentTrackContainer"]) {
		@synchronized(self) {
			hasPreCachedNextTrack = NO;
		}
		
		if ([self.playbackContext respondsToSelector:@selector(setPlayingTrackContainer:isPlaying:)]) {
			[self.playbackContext setPlayingTrackContainer:self.currentTrackContainer isPlaying:self.currentPlaybackProvider.isPlaying];
		}
		
	} else if ([keyPath isEqualToString:@"playbackContext"]) {
		
		id oldContext = [change valueForKey:NSKeyValueChangeOldKey];
		if (oldContext != nil && oldContext != [NSNull null]) {
			if ([oldContext respondsToSelector:@selector(setPlayingTrackContainer:isPlaying:)]) {
				[oldContext setPlayingTrackContainer:nil isPlaying:NO];
			}
		}
		
		id newContext = [change valueForKey:NSKeyValueChangeNewKey];
		if (newContext != nil && newContext != [NSNull null]) {
			if ([newContext respondsToSelector:@selector(setPlayingTrackContainer:isPlaying:)]) {
				[newContext setPlayingTrackContainer:self.currentTrackContainer isPlaying:self.currentPlaybackProvider.isPlaying];
			}
		}
		
	} else if ([keyPath isEqualToString:@"currentTrackPosition"]) {
		if (!hasPreCachedNextTrack && self.currentTrack.duration - self.currentTrackPosition <= kNextTrackCacheThreshold) {
			id <VivaTrackContainer> nextContainer = [self nextTrackContainerInCurrentContext];
			if (nextContainer != nil) {
				[self.currentPlaybackProvider preloadTrackForPlayback:nextContainer.track error:nil];
				@synchronized(self) {
					hasPreCachedNextTrack = YES;
				}
			}
		}
        
    } else if ([keyPath isEqualToString:@"volume"]) {
        [self applyVolumeToAudioUnit:self.volume];
        
    } else if ([keyPath isEqualToString:@"loopPlayback"]) {
        [[NSUserDefaults standardUserDefaults] setBool:self.loopPlayback forKey:kLoopPlaybackDefaultsKey];
        
    } else if ([keyPath isEqualToString:@"shufflePlayback"]) {
        [[NSUserDefaults standardUserDefaults] setBool:self.shufflePlayback forKey:kShufflePlaybackDefaultsKey];
        [self resetShuffledPool];
        if (self.shufflePlayback)
            [self addTrackContainerToShufflePool:self.currentTrackContainer];
        else
            [self resetShuffleHistory];
            
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Audio Processing

-(NSInteger)session:(SPSession *)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat {
	
	if (frameCount == 0) {
		[self.audioBuffer clear];
		return 0; // Audio discontinuity!
	}
    
    if (audioProcessingGraph == NULL) {
        NSError *error = nil;
        if (![self setupCoreAudioWithAudioFormat:audioFormat error:&error]) {
            NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
            return 0;
        }
    }
	
	NSUInteger frameByteSize = sizeof(sint16) * audioFormat->channels;
	NSUInteger dataLength = frameCount * frameByteSize;
	
	if ((self.audioBuffer.maximumLength - self.audioBuffer.length) < dataLength) {
		// Only allow whole deliveries in, since libSpotify wants us to consume whole frames, whereas
		// the buffer works in bytes, meaning we could consume a fraction of a frame.
		return 0;
	}

	[self.audioBuffer attemptAppendData:audioFrames ofLength:dataLength];
	return frameCount;
}

#pragma mark -
#pragma mark Core Audio Setup

-(void)applyBandsToAudioUnit {
	AudioUnitSetParameter(eqUnit, 0, kAudioUnitScope_Global, 0, (Float32)self.eqBands.band1, 0);
	AudioUnitSetParameter(eqUnit, 1, kAudioUnitScope_Global, 0, (Float32)self.eqBands.band2, 0);
	AudioUnitSetParameter(eqUnit, 2, kAudioUnitScope_Global, 0, (Float32)self.eqBands.band3, 0);
	AudioUnitSetParameter(eqUnit, 3, kAudioUnitScope_Global, 0, (Float32)self.eqBands.band4, 0);
	AudioUnitSetParameter(eqUnit, 4, kAudioUnitScope_Global, 0, (Float32)self.eqBands.band5, 0);
	AudioUnitSetParameter(eqUnit, 5, kAudioUnitScope_Global, 0, (Float32)self.eqBands.band6, 0);
	AudioUnitSetParameter(eqUnit, 6, kAudioUnitScope_Global, 0, (Float32)self.eqBands.band7, 0);
	AudioUnitSetParameter(eqUnit, 7, kAudioUnitScope_Global, 0, (Float32)self.eqBands.band8, 0);
	AudioUnitSetParameter(eqUnit, 8, kAudioUnitScope_Global, 0, (Float32)self.eqBands.band9, 0);
	AudioUnitSetParameter(eqUnit, 9, kAudioUnitScope_Global, 0, (Float32)self.eqBands.band10, 0);
}
         
-(void)applyVolumeToAudioUnit:(double)vol {
    
    if (audioProcessingGraph == NULL || outputUnit == NULL)
        return;
	
    AudioUnitSetParameter(outputUnit,
                          kHALOutputParam_Volume,
                          kAudioUnitScope_Output,
                          0,
                          (vol * vol * vol),
                          0);
}

-(void)startAudioQueue {
    if (audioProcessingGraph == NULL)
        return;
    
    AUGraphStart(audioProcessingGraph);
}

-(void)stopAudioQueue {
    if (audioProcessingGraph == NULL)
        return;
    
    AUGraphStop(audioProcessingGraph);
}

-(void)teardownCoreAudio {
    if (audioProcessingGraph == NULL)
        return;
    
    [self stopAudioQueue];
	
    AUGraphStop(audioProcessingGraph);
	AUGraphUninitialize(audioProcessingGraph);
	DisposeAUGraph(audioProcessingGraph);
	
	audioProcessingGraph = NULL;
	outputUnit = NULL;
	eqUnit = NULL;
}

static inline void fillWithError(NSError **mayBeAnError, NSString *localizedDescription, int code) {
    
    if (mayBeAnError == NULL)
        return;
    
    *mayBeAnError = [NSError errorWithDomain:@"com.vivaplaybackmanager.coreaudio"
                                        code:code
                                    userInfo:localizedDescription ? [NSDictionary dictionaryWithObject:localizedDescription
                                                                                                forKey:NSLocalizedDescriptionKey]
                                            : nil];
    
}

-(BOOL)setupCoreAudioWithAudioFormat:(const sp_audioformat *)audioFormat error:(NSError **)err {
    
    if (audioProcessingGraph != NULL)
        [self teardownCoreAudio];
    
    // A description of the output device we're looking for.
    AudioComponentDescription outputDescription;
    outputDescription.componentType = kAudioUnitType_Output;
    outputDescription.componentSubType = kAudioUnitSubType_DefaultOutput;
    outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    outputDescription.componentFlags = 0;
    outputDescription.componentFlagsMask = 0;
	
	// A description for the EQ Device
	AudioComponentDescription eqDescription;
	eqDescription.componentType = kAudioUnitType_Effect;
	eqDescription.componentSubType = kAudioUnitSubType_GraphicEQ;
	eqDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	eqDescription.componentFlags = 0;
    eqDescription.componentFlagsMask = 0;

	// A description for the libspotify -> standard PCM device
	AudioComponentDescription converterDescription;
	converterDescription.componentType = kAudioUnitType_FormatConverter;
	converterDescription.componentSubType = kAudioUnitSubType_AUConverter;
	converterDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	converterDescription.componentFlags = 0;
	converterDescription.componentFlagsMask = 0;	
    
    // Tell Core Audio about libspotify's audio format
    AudioStreamBasicDescription libSpotifyInputFormat;
    libSpotifyInputFormat.mSampleRate = (float)audioFormat->sample_rate;
    libSpotifyInputFormat.mFormatID = kAudioFormatLinearPCM;
    libSpotifyInputFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked | kAudioFormatFlagsNativeEndian;
    libSpotifyInputFormat.mBytesPerPacket = audioFormat->channels * sizeof(sint16);
    libSpotifyInputFormat.mFramesPerPacket = 1;
    libSpotifyInputFormat.mBytesPerFrame = libSpotifyInputFormat.mBytesPerPacket;
    libSpotifyInputFormat.mChannelsPerFrame = audioFormat->channels;
    libSpotifyInputFormat.mBitsPerChannel = 16;
    libSpotifyInputFormat.mReserved = 0;
	
	// Create an AUGraph
	OSErr status = NewAUGraph(&audioProcessingGraph);
	if (status != noErr) {
        fillWithError(err, @"Couldn't init graph", status);
        return NO;
    }
	
	// Open the graph. AudioUnits are open but not initialized (no resource allocation occurs here)
	AUGraphOpen(audioProcessingGraph);
	if (status != noErr) {
        fillWithError(err, @"Couldn't open graph", status);
        return NO;
    }

	// Add audio output...
	AUNode outputNode;
	status = AUGraphAddNode(audioProcessingGraph, &outputDescription, &outputNode);
	if (status != noErr) {
        fillWithError(err, @"Couldn't add output node", status);
        return NO;
    }
	
	// Get output unit so we can change volume etc
	status = AUGraphNodeInfo(audioProcessingGraph, outputNode, NULL, &outputUnit);
	if (status != noErr) {
        fillWithError(err, @"Couldn't get output unit", status);
        return NO;
    }
	
	// Create EQ!
	AUNode eqNode;
	status = AUGraphAddNode(audioProcessingGraph, &eqDescription, &eqNode);
	if (status != noErr) {
        fillWithError(err, @"Couldn't add eq node", status);
        return NO;
    }
	
	status = AUGraphNodeInfo(audioProcessingGraph, eqNode, NULL, &eqUnit);
	if (status != noErr) {
        fillWithError(err, @"Couldn't get eq unit", status);
        return NO;
    }
	
	// Set EQ to 10-band
	AudioUnitSetParameter(eqUnit, 10000, kAudioUnitScope_Global, 0, 0.0, 0);
	if (status != noErr) {
        fillWithError(err, @"Couldn't set eq node parameter", status);
        return NO;
    }
	
	// Connect EQ node to output
	status = AUGraphConnectNodeInput(audioProcessingGraph, eqNode, 0, outputNode, 0);
	if (status != noErr) {
        fillWithError(err, @"Couldn't connect nodes", status);
        return NO;
    }
	
	// Create PCM converter
	AUNode converterNode;
	status = AUGraphAddNode(audioProcessingGraph, &converterDescription, &converterNode);
	if (status != noErr) {
        fillWithError(err, @"Couldn't add converter node", status);
        return NO;
    }
	
	// Set stream format from libspotify format
	AudioUnit converterUnit;
	status = AUGraphNodeInfo(audioProcessingGraph, converterNode, NULL, &converterUnit);
	if (status != noErr) {
        fillWithError(err, @"Couldn't get converter unit", status);
        return NO;
    }
	
	status = AudioUnitSetProperty(converterUnit,
								  kAudioUnitProperty_StreamFormat,
								  kAudioUnitScope_Input,
								  0,
								  &libSpotifyInputFormat,
								  sizeof(libSpotifyInputFormat));
	if (status != noErr) {
        fillWithError(err, @"Couldn't set input format", status);
        return NO;
    }

	// Set render callback
	AURenderCallbackStruct rcbs;
	rcbs.inputProc = VivaAudioUnitRenderDelegateCallback;
	rcbs.inputProcRefCon = (__bridge void *)(self);
	
	status = AUGraphSetNodeInputCallback(audioProcessingGraph, converterNode, 0, &rcbs);
	if (status != noErr) {
        fillWithError(err, @"Couldn't add render callback", status);
        return NO;
    }
	
	// Connect converter to EQ
	// Connect EQ node to output
	status = AUGraphConnectNodeInput(audioProcessingGraph, converterNode, 0, eqNode, 0);
	if (status != noErr) {
        fillWithError(err, @"Couldn't connect converter->eq", status);
        return NO;
    }
	
	// Init Queue
	status = AUGraphInitialize(audioProcessingGraph);
	if (status != noErr) {
		fillWithError(err, @"Couldn't initialize graph", status);
        return NO;
	}
	
	AUGraphUpdate(audioProcessingGraph, NULL);
	
	//CAShow(audioProcessingGraph);
    
    [self startAudioQueue];
    [self applyVolumeToAudioUnit:self.volume];
    [self applyBandsToAudioUnit];
	
    return YES;
}

static UInt32 framesSinceLastTimeUpdate = 0;
static UInt32 framesSinceLastFFTUpdate = 0;

static OSStatus VivaAudioUnitRenderDelegateCallback(void *inRefCon,
                                                    AudioUnitRenderActionFlags *ioActionFlags,
                                                    const AudioTimeStamp *inTimeStamp,
                                                    UInt32 inBusNumber,
                                                    UInt32 inNumberFrames,
                                                    AudioBufferList *ioData) {
	
    VivaPlaybackManager *self = (__bridge VivaPlaybackManager *)inRefCon;
	
	AudioBuffer *buffer = &(ioData->mBuffers[0]);
	UInt32 bytesRequired = buffer->mDataByteSize;

	NSUInteger availableData = [self->audioBuffer length];
	if (availableData < bytesRequired) {
		buffer->mDataByteSize = 0;
		*ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
		return noErr;
    }
    
    buffer->mDataByteSize = (UInt32)[self->audioBuffer readDataOfLength:bytesRequired intoAllocatedBuffer:&buffer->mData];
    
	framesSinceLastTimeUpdate += inNumberFrames;
    framesSinceLastFFTUpdate += inNumberFrames;
	
	if (framesSinceLastTimeUpdate >= 8820) {
        // Update 5 times per second
		[self->incrementTrackPositionInvocation setArgument:&framesSinceLastTimeUpdate atIndex:2];
		[self->incrementTrackPositionInvocation performSelectorOnMainThread:@selector(invoke)
                                                                 withObject:nil
                                                              waitUntilDone:NO];
		framesSinceLastTimeUpdate = 0;
	}
    
    if (framesSinceLastFFTUpdate >= 2205) {
        short *frames = buffer->mData;
        performAcceleratedFastFourierTransformWithWaveform(self, frames, inNumberFrames, self->leftChannelMagnitudes, self->rightChannelMagnitudes);
        
        [self performSelectorOnMainThread:@selector(updateLevels)
                               withObject:nil
                            waitUntilDone:NO];
        
		framesSinceLastFFTUpdate = 0;
    }
    
    return noErr;
}

-(void)incrementTrackPositionWithFrameCount:(UInt32)framesToAppend {
    self.currentTrackPosition = self.currentTrackPosition + (double)framesToAppend/44100.0;
}

-(void)updateLevels {
    
	NSMutableArray *leftArray = [[NSMutableArray alloc] initWithCapacity:exp2(fftMagnitudeExponent)];
	NSMutableArray *rightArray = [[NSMutableArray alloc] initWithCapacity:exp2(fftMagnitudeExponent)];
	
	for (int currentLevel = 0; currentLevel < exp2(fftMagnitudeExponent); currentLevel++) {
        
        double left = leftChannelMagnitudes[currentLevel] / 10.0;
        double right = rightChannelMagnitudes[currentLevel] / 10.0;
        left = cbrt(MIN(1.0, MAX(0.0, left)));
        right = cbrt(MIN(1.0, MAX(0.0, right)));
        
        [leftArray addObject:[NSNumber numberWithDouble:left]];
        [rightArray addObject:[NSNumber numberWithDouble:right]];
    }
	
	self.leftLevels = leftArray;
    self.rightLevels = rightArray;
	

}

#pragma mark -
#pragma mark Fourier Transforms

static double *leftInputRealBuffer = NULL;
static double *leftInputImagBuffer = NULL;
static double *rightInputRealBuffer = NULL;
static double *rightInputImagBuffer = NULL;

static vDSP_Length fftSetupForSampleCount = 0;

static void performAcceleratedFastFourierTransformWithWaveform(VivaPlaybackManager *manager, short *frames, vDSP_Length frameCount, double *leftDestination, double *rightDestination) {
	if (leftDestination == NULL || rightDestination == NULL || frames == NULL || frameCount == 0)
		return;

    FFTSetupD fft_weights = manager->fft_weights;
    
    if (frameCount != fftSetupForSampleCount) {
        /* Allocate memory to store split-complex input and output data */
        
        if (leftInputRealBuffer != NULL) free(leftInputRealBuffer);
        if (leftInputImagBuffer != NULL) free(leftInputImagBuffer);
        
        leftInputRealBuffer = (double *)malloc(frameCount * sizeof(double));
        leftInputImagBuffer = (double *)malloc(frameCount * sizeof(double));
        
        if (rightInputRealBuffer != NULL) free(rightInputRealBuffer);
        if (rightInputImagBuffer != NULL) free(rightInputImagBuffer);
        
        rightInputRealBuffer = (double *)malloc(frameCount * sizeof(double));
        rightInputImagBuffer = (double *)malloc(frameCount * sizeof(double));
        
        fftSetupForSampleCount = frameCount;
    }
    
    memset(leftInputRealBuffer, 0, frameCount * sizeof(double));
    memset(rightInputRealBuffer, 0, frameCount * sizeof(double));
    memset(leftInputImagBuffer, 0, frameCount * sizeof(double));
    memset(rightInputImagBuffer, 0, frameCount * sizeof(double));
    
    DSPDoubleSplitComplex leftInput = {leftInputRealBuffer, leftInputImagBuffer};
    DSPDoubleSplitComplex rightInput = {rightInputRealBuffer, rightInputImagBuffer};
    
    // Left
    for (int i = 0; i < frameCount; i++) {
        leftInput.realp[i] = ((double)frames[i * 2]) / INT16_MAX;
        rightInput.realp[i] = ((double)frames[(i * 2) + 1]) / INT16_MAX;
    }
    
    /* 1D in-place complex FFT */
    vDSP_fft_zipD(fft_weights, &leftInput, 1, fftMagnitudeExponent, FFT_FORWARD);
    // Get magnitudes
    vDSP_zvmagsD(&leftInput, 1, leftDestination, 1, exp2(fftMagnitudeExponent));
    
    /* 1D in-place complex FFT */
    vDSP_fft_zipD(fft_weights, &rightInput, 1, fftMagnitudeExponent, FFT_FORWARD);
    // Get magnitudes
    vDSP_zvmagsD(&rightInput, 1, rightDestination, 1, exp2(fftMagnitudeExponent));   
}

#pragma mark -

-(void)dealloc {

	[self removeObserver:self forKeyPath:@"eqBands"];
    [self removeObserver:self forKeyPath:@"currentPlaybackProvider.playing"];
	[self removeObserver:self forKeyPath:@"currentTrackContainer"];
	[self removeObserver:self forKeyPath:@"currentTrackPosition"];
	[self removeObserver:self forKeyPath:@"playbackContext"];
    [self removeObserver:self forKeyPath:@"volume"];
    [self removeObserver:self forKeyPath:@"loopPlayback"];
    [self removeObserver:self forKeyPath:@"shufflePlayback"];
	
	[self.audioBuffer clear];
	[self teardownCoreAudio];
	
	// vDSP
	vDSP_destroy_fftsetupD(fft_weights);
	free(leftChannelMagnitudes);
	free(rightChannelMagnitudes);
	

}

@end
