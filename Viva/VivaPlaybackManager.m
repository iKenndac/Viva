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
-(void)startAudioUnit;
-(void)stopAudioUnit;
-(void)applyVolumeToAudioUnit:(double)vol;

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
    
    AudioUnit outputAudioUnit;
    
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

@synthesize leftLevels;
@synthesize rightLevels;

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
            if (potentialContainer.track.availability == SP_TRACK_AVAILABILITY_AVAILABLE) {
                container = potentialContainer;
                break;
            }
        }
    }
        
    
    NSError *error = nil;
    if (container && [self playTrackContainerInCurrentContext:container error:&error]) {
        self.currentPlaybackProvider.playing = YES;
    } else if (error) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
    }
}

-(BOOL)playTrackContainerInCurrentContext:(id <VivaTrackContainer>)newTrack error:(NSError **)error {
	
	// Don't clear out the audio buffer just in case we can manage gapless playback.
    self.currentTrackPosition = 0.0;    
    
	if (newTrack.track.spotifyURL.spotifyLinkType == SP_LINKTYPE_LOCALTRACK) {
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
        
        while (!nextTrack.track.availability == SP_TRACK_AVAILABILITY_AVAILABLE) {
            
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
        
        while (!previousTrack.track.availability == SP_TRACK_AVAILABILITY_AVAILABLE) {
            
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
        if (trackContainer.track.availability != SP_TRACK_AVAILABILITY_AVAILABLE)
            [unavailableTracks addObject:trackContainer];
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

-(void)sessionDidLosePlayToken:(SPSession *)aSession {}

-(void)sessionDidEndPlayback:(SPSession *)aSession {
	// Not routing this through to the main thread causes odd locks and crashes.
	[self performSelectorOnMainThread:@selector(sessionDidEndPlaybackOnMainThread:)
						   withObject:aSession
						waitUntilDone:NO];
}

-(void)sessionDidEndPlaybackOnMainThread:(SPSession *)aSession {
	[self skipToNextTrackInCurrentContext:NO];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
	if ([keyPath isEqualToString:@"currentPlaybackProvider.playing"]) {
        
        if (self.currentPlaybackProvider.playing) {
            [self startAudioUnit];
        } else {
            [self stopAudioUnit];
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
    
    if (outputAudioUnit == NULL) {
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
         
-(void)applyVolumeToAudioUnit:(double)vol {
    
    if (outputAudioUnit == NULL)
        return;
    
    AudioUnitSetParameter(outputAudioUnit,
                          kHALOutputParam_Volume,
                          kAudioUnitScope_Output,
                          0,
                          (vol * vol * vol),
                          0);
}

-(void)startAudioUnit {
    if (outputAudioUnit == NULL)
        return;
    
    AudioOutputUnitStart(outputAudioUnit);
}

-(void)stopAudioUnit {
    if (outputAudioUnit == NULL)
        return;
    
    AudioOutputUnitStop(outputAudioUnit);
}

-(void)teardownCoreAudio {
    if (outputAudioUnit == NULL)
        return;
    
    [self stopAudioUnit];
    AudioUnitUninitialize(outputAudioUnit);
    CloseComponent(outputAudioUnit);
    
    outputAudioUnit = NULL;
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
    
    if (outputAudioUnit != NULL)
        [self teardownCoreAudio];
    
    // A description of the output device we're looking for.
    ComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_DefaultOutput;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    // Find a component that meets the description's specifications
    Component comp = FindNextComponent(NULL, &desc);
    
    if (comp == NULL) {
        fillWithError(err, @"Could not find a component that matches our specifications", -1);
        return NO;
    }

    // Gain access to the services provided by the component, i.e. find our
    // output device
    OSErr status = OpenAComponent(comp, &outputAudioUnit);
    if (status != noErr) {
        fillWithError(err, @"Couldn't find a device that matched our criteria", status);
        return NO;
    }
    
    // Tell Core Audio about libspotify's audio format
    AudioStreamBasicDescription outputFormat;
    outputFormat.mSampleRate = (float)audioFormat->sample_rate;
    outputFormat.mFormatID = kAudioFormatLinearPCM;
    outputFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked | kAudioFormatFlagsNativeEndian;
    outputFormat.mBytesPerPacket = audioFormat->channels * sizeof(sint16);
    outputFormat.mFramesPerPacket = 1;
    outputFormat.mBytesPerFrame = outputFormat.mBytesPerPacket;
    outputFormat.mChannelsPerFrame = audioFormat->channels;
    outputFormat.mBitsPerChannel = 16;
    outputFormat.mReserved = 0;
    
    status = AudioUnitSetProperty(outputAudioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &outputFormat,
                                  sizeof(outputFormat));
    if (status != noErr) {
        fillWithError(err, @"Couldn't set output format", status);
        return NO;
    }
    
    AURenderCallbackStruct callback;
    callback.inputProc = VivaAudioUnitRenderDelegateCallback;
    callback.inputProcRefCon = (__bridge void *)(self);
    
    status = AudioUnitSetProperty(outputAudioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  0,
                                  &callback,
                                  sizeof(callback));
    if (status != noErr) {
        fillWithError(err, @"Couldn't set render callback", status);
        return NO;
    }
    
    status = AudioUnitInitialize(outputAudioUnit);
    if (status != noErr) {
        fillWithError(err, @"Couldn't initialize audio unit", status);
        return NO;
    }
    
    [self startAudioUnit];
    [self applyVolumeToAudioUnit:self.volume];
    
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
