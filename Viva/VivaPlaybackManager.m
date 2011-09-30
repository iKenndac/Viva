//
//  VivaPlaybackManager.m
//  Viva
//
//  Created by Daniel Kennett on 3/30/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaPlaybackManager.h"
#import "Constants.h"
#include <sys/time.h>

@interface VivaPlaybackManager  ()

@property (retain, readwrite) SPCircularBuffer *audioBuffer;
@property (retain, readwrite) id <VivaPlaybackContext> playbackContext;
@property (readwrite, retain) id <VivaTrackContainer> currentTrackContainer;
@property (readwrite, retain) SPSession *playbackSession;

-(void)playTrackContainerInCurrentContext:(id <VivaTrackContainer>)newTrack;

-(id <VivaTrackContainer>)nextTrackContainerInCurrentContext;
-(id <VivaTrackContainer>)previousTrackContainerInCurrentContext;

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

- (void)performAcceleratedFastFourierTransformWithWaveform:(float *)waveformArray intoStore:(double *)magnitudes;

@property (readwrite, retain) NSArray *leftLevels;
@property (readwrite, retain) NSArray *rightLevels;

@end

#define kMaximumBytesInBuffer 44100 * 2 * 2 * 0.5 // 0.5 Second @ 44.1kHz, 16bit per channel, stereo

static NSUInteger const fftWaveCount = 512;
static NSUInteger const fftMagnitudeCount = 16; // Must be power of two

@implementation VivaPlaybackManager

- (id)initWithPlaybackSession:(SPSession *)aSession {
    self = [super init];
    if (self) {
        // Initialization code here.
		
		SEL incrementTrackPositionSelector = @selector(incrementTrackPositionWithFrameCount:);
		incrementTrackPositionMethodSignature = [[VivaPlaybackManager instanceMethodSignatureForSelector:incrementTrackPositionSelector] retain];
		incrementTrackPositionInvocation = [[NSInvocation invocationWithMethodSignature:incrementTrackPositionMethodSignature] retain];
		[incrementTrackPositionInvocation setSelector:incrementTrackPositionSelector];
		[incrementTrackPositionInvocation setTarget:self];
		
		self.volume = 1.0;
		self.playbackSession = aSession;
		self.playbackSession.playbackDelegate = self;
        
		self.audioBuffer = [[[SPCircularBuffer alloc] initWithMaximumLength:kMaximumBytesInBuffer] autorelease];
		
        [self addObserver:self
               forKeyPath:@"playbackSession.playing"
                  options:0
                  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"currentTrackContainer"
				  options:0
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
		
		// Playback
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(playTrackFromUserAction:)
													 name:kTrackShouldBePlayedNotification
												   object:nil];

		/* Setup weights (twiddle factors) */
		fft_weights = vDSP_create_fftsetupD((int)sqrt(fftMagnitudeCount), kFFTRadix2);
		
		/* Allocate memory to store split-complex input and output data */
		input.realp = (double *)malloc(fftWaveCount * sizeof(double));
		input.imagp = (double *)malloc(fftWaveCount * sizeof(double));
		leftChannelMagnitudes = (double *)malloc(fftMagnitudeCount * sizeof(double));
		rightChannelMagnitudes = (double *)malloc(fftMagnitudeCount * sizeof(double));
    }
    
    return self;
}

@synthesize audioBuffer;
@synthesize playbackContext;
@synthesize currentTrackContainer;
@synthesize playbackSession;
@synthesize currentTrackPosition;
@synthesize volume;
@synthesize loopPlayback;

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

-(void)playTrackFromUserAction:(NSNotification *)aNotification {
	
	// User double-clicked, so reset everything and start again.
	[self.playbackSession setPlaying:NO];
	[self.playbackSession unloadPlayback];
	[self teardownCoreAudio];
	
	[self.audioBuffer clear];
	
	id <VivaTrackContainer> container = [[aNotification userInfo] valueForKey:kPlaybackInitialTrackContainerKey];
	
	if ([[aNotification object] conformsToProtocol:@protocol(VivaPlaybackContext)]) {
		self.playbackContext = [aNotification object];
	}
	
	[self playTrackContainerInCurrentContext:container];
	self.playbackSession.playing = YES;
}

-(void)playTrackContainerInCurrentContext:(id <VivaTrackContainer>)newTrack {
	
	// Don't clear out the audio buffer just in case we can manage gapless playback.
	self.currentTrackContainer = newTrack;
	self.currentTrackPosition = 0.0;
	[self.playbackSession playTrack:self.currentTrackContainer.track error:nil];
}
	
-(void)seekToTrackPosition:(NSTimeInterval)newPosition {
	if (newPosition <= self.currentTrack.duration) {
		[self.playbackSession seekPlaybackToOffset:newPosition];
		self.currentTrackPosition = newPosition;
	}	
}

-(id <VivaTrackContainer>)nextTrackContainerInCurrentContext {
	
	NSUInteger currentTrackIndex = [self.playbackContext.trackContainersForPlayback indexOfObject:self.currentTrackContainer];
	
	if (currentTrackIndex == NSNotFound ||
		(currentTrackIndex == [self.playbackContext.trackContainersForPlayback count] - 1 && !self.loopPlayback)) {
		return nil;
	} else if (currentTrackIndex == [self.playbackContext.trackContainersForPlayback count] - 1) {
		return [self.playbackContext.trackContainersForPlayback objectAtIndex:0];
	} else {
		return [self.playbackContext.trackContainersForPlayback objectAtIndex:currentTrackIndex + 1];
	}
}

-(void)skipToNextTrackInCurrentContext:(BOOL)clearExistingAudioBuffers {
	
	BOOL wasPlaying = self.playbackSession.playing;
	
	if (clearExistingAudioBuffers) {
		[self.playbackSession setPlaying:NO];
		[self.playbackSession unloadPlayback];
		[self teardownCoreAudio];
		
		[self.audioBuffer clear];
	}
	
	id <VivaTrackContainer> nextContainer = [self nextTrackContainerInCurrentContext];
	
	if (nextContainer != nil) {
		[self playTrackContainerInCurrentContext:nextContainer];	
		self.playbackSession.playing = wasPlaying;
	} else {
		self.currentTrackContainer = nil;
		[self teardownCoreAudio];
		self.currentTrackPosition = 0;
	}
}

-(id <VivaTrackContainer>)previousTrackContainerInCurrentContext {
	
	NSUInteger currentTrackIndex = [self.playbackContext.trackContainersForPlayback indexOfObject:self.currentTrackContainer];
	
	if (currentTrackIndex == NSNotFound ||
		(currentTrackIndex == 0 && !self.loopPlayback)) {
		return nil;
	} else if (currentTrackIndex == 0) {
		return [self.playbackContext.trackContainersForPlayback objectAtIndex:[self.playbackContext.trackContainersForPlayback count] - 1];
	} else {
		return [self.playbackContext.trackContainersForPlayback objectAtIndex:currentTrackIndex - 1];
	}
}

-(void)skipToPreviousTrackInCurrentContext:(BOOL)clearExistingAudioBuffers {
	
	BOOL wasPlaying = self.playbackSession.playing;
	
	if (clearExistingAudioBuffers) {
		[self.playbackSession setPlaying:NO];
		[self.playbackSession unloadPlayback];
		[self teardownCoreAudio];
		
		[self.audioBuffer clear];
	}
	
	id <VivaTrackContainer> previousContainer = [self previousTrackContainerInCurrentContext];
	
	if (previousContainer != nil) {
		[self playTrackContainerInCurrentContext:previousContainer];	
		self.playbackSession.playing = wasPlaying;
	} else {
		self.currentTrackContainer = nil;
		[self teardownCoreAudio];
		self.currentTrackPosition = 0;
	}
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
    if ([keyPath isEqualToString:@"playbackSession.playing"]) {
        
        if (self.playbackSession.playing) {
            [self startAudioUnit];
        } else {
            [self stopAudioUnit];
        }
		
		if ([self.playbackContext respondsToSelector:@selector(setPlayingTrackContainer:isPlaying:)]) {
			[self.playbackContext setPlayingTrackContainer:self.currentTrackContainer isPlaying:self.playbackSession.isPlaying];
		}
		
	} else if ([keyPath isEqualToString:@"currentTrackContainer"]) {
		@synchronized(self) {
			hasPreCachedNextTrack = NO;
		}
		
		if ([self.playbackContext respondsToSelector:@selector(setPlayingTrackContainer:isPlaying:)]) {
			[self.playbackContext setPlayingTrackContainer:self.currentTrackContainer isPlaying:self.playbackSession.isPlaying];
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
				[newContext setPlayingTrackContainer:self.currentTrackContainer isPlaying:self.playbackSession.isPlaying];
			}
		}
		
	} else if ([keyPath isEqualToString:@"currentTrackPosition"]) {
		if (!hasPreCachedNextTrack && self.currentTrack.duration - self.currentTrackPosition <= kNextTrackCacheThreshold) {
			id <VivaTrackContainer> nextContainer = [self nextTrackContainerInCurrentContext];
			if (nextContainer != nil) {
				[self.playbackSession preloadTrackForPlayback:nextContainer.track error:nil];
				@synchronized(self) {
					hasPreCachedNextTrack = YES;
				}
			}
		}
        
    } else if ([keyPath isEqualToString:@"volume"]) {
        [self applyVolumeToAudioUnit:self.volume];
        
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
    callback.inputProcRefCon = self;
    
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

static UInt32 framesSinceLastUpdate = 0;

static OSStatus VivaAudioUnitRenderDelegateCallback(void *inRefCon,
                                                    AudioUnitRenderActionFlags *ioActionFlags,
                                                    const AudioTimeStamp *inTimeStamp,
                                                    UInt32 inBusNumber,
                                                    UInt32 inNumberFrames,
                                                    AudioBufferList *ioData) {
    VivaPlaybackManager *self = inRefCon;
	
	AudioBuffer *buffer = &(ioData->mBuffers[0]);
	UInt32 bytesRequired = buffer->mDataByteSize;

	NSUInteger availableData = [self->audioBuffer length];
	if (availableData < bytesRequired) {
		buffer->mDataByteSize = 0;
		*ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
		return noErr;
    }
    
    buffer->mDataByteSize = (UInt32)[self->audioBuffer readDataOfLength:bytesRequired intoAllocatedBuffer:&buffer->mData];
    
	framesSinceLastUpdate += inNumberFrames;
	
	if (framesSinceLastUpdate >= 8820) {
        // Update 5 times per second
		[self->incrementTrackPositionInvocation setArgument:&framesSinceLastUpdate atIndex:2];
		[self->incrementTrackPositionInvocation performSelectorOnMainThread:@selector(invoke)
                                                                 withObject:nil
                                                              waitUntilDone:NO];
		framesSinceLastUpdate = 0;
	}
    
    return noErr;
}

-(void)incrementTrackPositionWithFrameCount:(UInt32)framesToAppend {
    self.currentTrackPosition = self.currentTrackPosition + (double)framesToAppend/44100.0;
}


- (void)performAcceleratedFastFourierTransformWithWaveform:(float *)waveformArray intoStore:(double *)magnitudes;
{   
	if (magnitudes == NULL || waveformArray == NULL)
		return;
	
    for (NSUInteger currentInputSampleIndex = 0; currentInputSampleIndex < fftWaveCount; currentInputSampleIndex++) {
        input.realp[currentInputSampleIndex] = (double)waveformArray[currentInputSampleIndex];
        input.imagp[currentInputSampleIndex] = 0.0f;
    }
	
    /* 1D in-place complex FFT */
    vDSP_fft_zipD(fft_weights, &input, 1, (int)sqrt(fftMagnitudeCount), FFT_FORWARD);
	
    // Get magnitudes
    vDSP_zvmagsD(&input, 1, magnitudes, 1, fftMagnitudeCount);
}

#pragma mark -

- (void)dealloc {

    [self removeObserver:self forKeyPath:@"playbackSession.playing"];
	[self removeObserver:self forKeyPath:@"currentTrackContainer"];
	[self removeObserver:self forKeyPath:@"currentTrackPosition"];
	[self removeObserver:self forKeyPath:@"playbackContext"];
    [self removeObserver:self forKeyPath:@"volume"];
	
	[incrementTrackPositionInvocation release];
	[incrementTrackPositionMethodSignature release];
	
	[self.audioBuffer clear];
	self.audioBuffer = nil;
    self.currentTrackContainer = nil;
	self.playbackContext = nil;
	[self teardownCoreAudio];
	self.playbackSession = nil;
	
	// vDSP
	vDSP_destroy_fftsetupD(fft_weights);
	free(input.realp);
	free(input.imagp);
	free(leftChannelMagnitudes);
	free(rightChannelMagnitudes);
	
	self.leftLevels = nil;
	self.rightLevels = nil;

    [super dealloc];
}

@end
