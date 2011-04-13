//
//  VivaPlaybackManager.m
//  Viva
//
//  Created by Daniel Kennett on 3/30/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaPlaybackManager.h"
#import "Constants.h"

@interface VivaPlaybackManager  ()

@property (retain, readwrite) SPCircularBuffer *audioBuffer;
@property (retain, readwrite) CoCAAudioUnit *audioUnit;
@property (retain, readwrite) id <VivaPlaybackContext> playbackContext;
@property (readwrite, retain) SPSpotifyTrack *currentTrack;
@property (readwrite, retain) SPSpotifySession *playbackSession;

-(void)clearAudioBuffer;
-(void)playTrackInCurrentContext:(SPSpotifyTrack *)newTrack;

-(SPSpotifyTrack *)nextTrackInCurrentContext;
-(SPSpotifyTrack *)previousTrackInCurrentContext;

@end

#define kMaximumBytesInBuffer 44100 * 2 * 2 * 0.5 // 0.5 Second @ 44.1kHz, 16bit per channel, stereo

@implementation VivaPlaybackManager

- (id)initWithPlaybackSession:(SPSpotifySession *)aSession {
    self = [super init];
    if (self) {
        // Initialization code here.
		
		self.volume = 1.0;
		self.playbackSession = aSession;
        
		self.audioBuffer = [[[SPCircularBuffer alloc] initWithMaximumLength:kMaximumBytesInBuffer] autorelease];
		
        [self addObserver:self
               forKeyPath:@"playbackSession.isPlaying"
                  options:0
                  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"currentTrack"
				  options:0
				  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"currentTrackPosition"
				  options:0
				  context:nil];
		
		// Playback
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(playTrackFromUserAction:)
													 name:kTrackShouldBePlayedNotification
												   object:nil];
    }
    
    return self;
}

@synthesize audioBuffer;
@synthesize audioUnit;
@synthesize playbackContext;
@synthesize currentTrack;
@synthesize playbackSession;
@synthesize currentTrackPosition;
@synthesize volume;
@synthesize loopPlayback;

+(NSSet *)keyPathsForValuesAffectingCanSkipToNextTrack {
	return [NSSet setWithObjects:@"loopPlayback", @"currentTrack", nil];
}

-(BOOL)canSkipToNextTrack {
	return (self.loopPlayback || 
			[self.playbackContext.tracksForPlayback indexOfObject:self.currentTrack] != [self.playbackContext.tracksForPlayback count] - 1);			
}

+(NSSet *)keyPathsForValuesAffectingCanSkipToPreviousTrack {
	return [NSSet setWithObjects:@"loopPlayback", @"currentTrack", nil];
}

-(BOOL)canSkipToPreviousTrack {
	return (self.loopPlayback || 
			[self.playbackContext.tracksForPlayback indexOfObject:self.currentTrack] != 0);			
}

#pragma mark -

-(void)playTrackFromUserAction:(NSNotification *)aNotification {
	
	// User double-clicked, so reset everything and start again.
	[self.playbackSession setIsPlaying:NO];
	[self.playbackSession unloadPlayback];
	[self.audioUnit stop];
	self.audioUnit = nil;
	
	[self clearAudioBuffer];
	
	SPSpotifyTrack *track = [[aNotification userInfo] valueForKey:kPlaybackInitialTrackKey];
	
	if ([[aNotification object] conformsToProtocol:@protocol(VivaPlaybackContext)]) {
		self.playbackContext = [aNotification object];
	}
	
	[self playTrackInCurrentContext:track];
	self.playbackSession.isPlaying = YES;
}

-(void)playTrackInCurrentContext:(SPSpotifyTrack *)newTrack {
	
	// Don't clear out the audio buffer just in case we can manage gapless playback.
	self.currentTrack = newTrack;
	self.currentTrackPosition = 0.0;
	[self.playbackSession playTrack:newTrack];
}
	
-(void)seekToTrackPosition:(NSTimeInterval)newPosition {
	if (newPosition <= self.currentTrack.duration) {
		[self.playbackSession seekPlaybackToOffset:newPosition];
		self.currentTrackPosition = newPosition;
	}	
}

-(SPSpotifyTrack *)nextTrackInCurrentContext {
	
	// WARNING: This logic falls over as soon as you have the same track in a context more than once.
	NSUInteger currentTrackIndex = [self.playbackContext.tracksForPlayback indexOfObject:currentTrack];
	
	if (currentTrackIndex == NSNotFound ||
		(currentTrackIndex == [self.playbackContext.tracksForPlayback count] - 1 && !self.loopPlayback)) {
		return nil;
	} else if (currentTrackIndex == [self.playbackContext.tracksForPlayback count] - 1) {
		return [self.playbackContext.tracksForPlayback objectAtIndex:0];
	} else {
		return [self.playbackContext.tracksForPlayback objectAtIndex:currentTrackIndex + 1];
	}
}

-(void)skipToNextTrackInCurrentContext:(BOOL)clearExistingAudioBuffers {
	
	BOOL wasPlaying = self.playbackSession.isPlaying;
	
	if (clearExistingAudioBuffers) {
		[self.playbackSession setIsPlaying:NO];
		[self.playbackSession unloadPlayback];
		[self.audioUnit stop];
		self.audioUnit = nil;
		
		[self clearAudioBuffer];
	}
	
	SPSpotifyTrack *nextTrack = [self nextTrackInCurrentContext];
	
	if (nextTrack != nil) {
		[self playTrackInCurrentContext:nextTrack];	
		self.playbackSession.isPlaying = wasPlaying;
	} else {
		self.currentTrack = nil;
		[self.audioUnit stop];
		self.audioUnit = nil;
		self.currentTrackPosition = 0;
	}
}

-(SPSpotifyTrack *)previousTrackInCurrentContext {
	
	// WARNING: This logic falls over as soon as you have the same track in a context more than once.
	NSUInteger currentTrackIndex = [self.playbackContext.tracksForPlayback indexOfObject:currentTrack];
	
	if (currentTrackIndex == NSNotFound ||
		(currentTrackIndex == 0 && !self.loopPlayback)) {
		return nil;
	} else if (currentTrackIndex == 0) {
		return [self.playbackContext.tracksForPlayback objectAtIndex:[self.playbackContext.tracksForPlayback count] - 1];
	} else {
		return [self.playbackContext.tracksForPlayback objectAtIndex:currentTrackIndex - 1];
	}
}

-(void)skipToPreviousTrackInCurrentContext:(BOOL)clearExistingAudioBuffers {
	
	BOOL wasPlaying = self.playbackSession.isPlaying;
	
	if (clearExistingAudioBuffers) {
		[self.playbackSession setIsPlaying:NO];
		[self.playbackSession unloadPlayback];
		[self.audioUnit stop];
		self.audioUnit = nil;
		
		[self clearAudioBuffer];
	}
	
	SPSpotifyTrack *previousTrack = [self previousTrackInCurrentContext];
	
	if (previousTrack != nil) {
		[self playTrackInCurrentContext:previousTrack];	
		self.playbackSession.isPlaying = wasPlaying;
	} else {
		self.currentTrack = nil;
		[self.audioUnit stop];
		self.audioUnit = nil;
		self.currentTrackPosition = 0;
	}
}

-(void)clearAudioBuffer {
	
	[self.audioBuffer clear];
}

#pragma mark -
#pragma mark Playback Callbacks

-(void)sessionDidLosePlayToken:(SPSpotifySession *)aSession {}

-(void)sessionDidEndPlayback:(SPSpotifySession *)aSession {
	// Not routing this through to the main thread causes odd locks and crashes.
	[self performSelectorOnMainThread:@selector(sessionDidEndPlaybackOnMainThread:)
						   withObject:aSession
						waitUntilDone:NO];
}

-(void)sessionDidEndPlaybackOnMainThread:(SPSpotifySession *)aSession {
	
	[self skipToNextTrackInCurrentContext:NO];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"playbackSession.isPlaying"]) {
        
        if (self.playbackSession.isPlaying) {
            [self.audioUnit start];
        } else {
            [self.audioUnit stop];
        }
		
	} else if ([keyPath isEqualToString:@"currentTrack"]) {
		@synchronized(self) {
			hasPreCachedNextTrack = NO;
		}
	} else if ([keyPath isEqualToString:@"currentTrackPosition"]) {
		if (!hasPreCachedNextTrack && self.currentTrack.duration - self.currentTrackPosition <= kNextTrackCacheThreshold) {
			SPSpotifyTrack *nextTrack = [self nextTrackInCurrentContext];
			if (nextTrack != nil) {
				[self.playbackSession preloadTrackForPlayback:nextTrack];
				@synchronized(self) {
					hasPreCachedNextTrack = YES;
				}
			}
		}
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Audio Processing

-(NSInteger)session:(SPSpotifySession *)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat {
	
	if (frameCount == 0) {
		[self clearAudioBuffer];
		return 0; // Audio discontinuity!
	}
	
	NSUInteger frameByteSize = sizeof(sint16) * audioFormat->channels;
	NSUInteger dataLength = frameCount * frameByteSize;
	
	if ((self.audioBuffer.maximumLength - self.audioBuffer.length) < dataLength) {
		// Only allow whole deliveries in, since libSpotify wants us to consume whole frames, whereas
		// the buffer works in bytes, meaning we could consume a fraction of a frame.
		return 0;
	}
	
	[self.audioBuffer attemptAppendData:audioFrames ofLength:dataLength];
	
	if (self.audioUnit == nil) {
		self.audioUnit = [CoCAAudioUnit defaultOutputUnit];
		[self.audioUnit setRenderDelegate:self];
		[self.audioUnit setup];
    }
	
    [self.audioUnit start];
	
	return frameCount;
}

static UInt32 framesSinceLastUpdate = 0;

-(OSStatus)audioUnit:(CoCAAudioUnit*)audioUnit
     renderWithFlags:(AudioUnitRenderActionFlags*)ioActionFlags
                  at:(const AudioTimeStamp*)inTimeStamp
               onBus:(UInt32)inBusNumber
          frameCount:(UInt32)inNumberFrames
           audioData:(AudioBufferList *)ioData;
{	
    // Core Audio generally expects audio data to be in native-endian 32-bit floating-point linear PCM format.
	
	AudioBuffer *leftBuffer = &(ioData->mBuffers[0]);
	AudioBuffer *rightBuffer = &(ioData->mBuffers[1]);
	
	NSUInteger bytesRequired = inNumberFrames * 2 * 2; // 16bit per channel, stereo
	void *frameBuffer = NULL;
	
	@synchronized(audioBuffer) {
		NSUInteger availableData = [audioBuffer length];
		if (availableData >= bytesRequired) {
			[audioBuffer readDataOfLength:bytesRequired intoBuffer:&frameBuffer];
			// We've done a length check just above, so hopefully we don't have to care about  how much was read.
		} else {
			leftBuffer->mDataByteSize = 0;
			rightBuffer->mDataByteSize = 0;
			*ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
			return noErr;
		}
	}
	
	float *leftChannelBuffer = leftBuffer->mData;
	float *rightChannelBuffer = rightBuffer->mData;
	
	sint16 *frames = frameBuffer;
	double effectiveVolume = self.volume;
	
	for (NSUInteger currentFrame = 0; currentFrame < inNumberFrames; currentFrame++) {

		// Convert the frames from 16-bit signed integers to floating point, then apply the volume.
		leftChannelBuffer[currentFrame] = (frames[currentFrame * 2]/(float)INT16_MAX) * effectiveVolume;
		rightChannelBuffer[currentFrame] = (frames[(currentFrame * 2) + 1]/(float)INT16_MAX) * effectiveVolume;
	}
	
	if (frameBuffer != NULL) 
		free(frameBuffer);
	frames = NULL;
	
	framesSinceLastUpdate += inNumberFrames;
	
	if (framesSinceLastUpdate >= 8820) {
		// Update 5 times per second.
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSTimeInterval newTrackPosition = self.currentTrackPosition + (double)framesSinceLastUpdate/44100.0;
		
		SEL setTrackPositionSelector = @selector(setCurrentTrackPosition:);
		NSMethodSignature *aSignature = [VivaPlaybackManager instanceMethodSignatureForSelector:setTrackPositionSelector];
		NSInvocation *anInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
		[anInvocation setSelector:setTrackPositionSelector];
		[anInvocation setTarget:self];
		[anInvocation setArgument:&newTrackPosition atIndex:2];
		
		[anInvocation performSelectorOnMainThread:@selector(invoke)
									   withObject:nil
									waitUntilDone:NO];
		[pool drain];
		
		framesSinceLastUpdate = 0;
	}
    
    return noErr;
}

- (void)dealloc {

    [self removeObserver:self forKeyPath:@"playbackSession.isPlaying"];
	
	[self clearAudioBuffer];
	self.audioBuffer = nil;
    self.currentTrack = nil;
	self.playbackContext = nil;
	[self.audioUnit stop];
	self.audioUnit = nil;
	self.playbackSession = nil;
	
    [super dealloc];
}

@end
