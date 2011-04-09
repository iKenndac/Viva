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

@property (retain, readwrite) NSPointerArray *frameBuffer;
@property (retain, readwrite) CoCAAudioUnit *audioUnit;
@property (retain, readwrite) id <VivaPlaybackContext> playbackContext;
@property (readwrite, retain) SPSpotifyTrack *currentTrack;
@property (readwrite, retain) SPSpotifySession *playbackSession;

-(void)clearAudioBuffer;
-(void)playTrackInCurrentContext:(SPSpotifyTrack *)newTrack;

@end

#define kMaximumFramesInBuffer 44100 // 1 Second

@implementation VivaPlaybackManager

- (id)initWithPlaybackSession:(SPSpotifySession *)aSession {
    self = [super init];
    if (self) {
        // Initialization code here.
		
		self.volume = 1.0;
		self.playbackSession = aSession;
        
		self.frameBuffer = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality];
		
        [self addObserver:self
               forKeyPath:@"playbackSession.isPlaying"
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

@synthesize frameBuffer;
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

-(void)skipToNextTrackInCurrentContext:(BOOL)clearExistingAudioBuffers {
	
	if (clearExistingAudioBuffers) {
		[self.playbackSession setIsPlaying:NO];
		[self.playbackSession unloadPlayback];
		[self.audioUnit stop];
		self.audioUnit = nil;
		
		[self clearAudioBuffer];
	}
	
	// WARNING: This logic falls over as soon as you have the same track in a context more than once.
	NSUInteger currentTrackIndex = [self.playbackContext.tracksForPlayback indexOfObject:currentTrack];
	
	if (currentTrackIndex == NSNotFound ||
		(currentTrackIndex == [self.playbackContext.tracksForPlayback count] - 1 && !self.loopPlayback)) {
		
		self.currentTrack = nil;
		[self.audioUnit stop];
		self.audioUnit = nil;
		self.currentTrackPosition = 0;
		
	} else if (currentTrackIndex == [self.playbackContext.tracksForPlayback count] - 1) {
		[self playTrackInCurrentContext:[self.playbackContext.tracksForPlayback objectAtIndex:0]];
	} else {
		[self playTrackInCurrentContext:[self.playbackContext.tracksForPlayback objectAtIndex:currentTrackIndex + 1]];
	}
}

-(void)skipToPreviousTrackInCurrentContext:(BOOL)clearExistingAudioBuffers {
	
	[self.playbackSession setIsPlaying:NO];
	[self.playbackSession unloadPlayback];
	[self.audioUnit stop];
	self.audioUnit = nil;
	
	[self clearAudioBuffer];
	
	// WARNING: This logic falls over as soon as you have the same track in a context more than once.
	NSUInteger currentTrackIndex = [self.playbackContext.tracksForPlayback indexOfObject:currentTrack];
	
	if (currentTrackIndex == NSNotFound ||
		(currentTrackIndex == 0 && !self.loopPlayback)) {
		
		self.currentTrack = nil;
		[self.audioUnit stop];
		self.audioUnit = nil;
		self.currentTrackPosition = 0;
		
	} else if (currentTrackIndex == 0) {
		[self playTrackInCurrentContext:[self.playbackContext.tracksForPlayback objectAtIndex:[self.playbackContext.tracksForPlayback count] - 1]];
	} else {
		[self playTrackInCurrentContext:[self.playbackContext.tracksForPlayback objectAtIndex:currentTrackIndex - 1]];
	}

}

-(void)clearAudioBuffer {
	
	@synchronized(frameBuffer) {
		for (NSUInteger currentFrame = 0; currentFrame < [self.frameBuffer count]; currentFrame++) {
			void *ptr = [self.frameBuffer pointerAtIndex:currentFrame];
			if (ptr != NULL) {
				free(ptr);
				[self.frameBuffer replacePointerAtIndex:currentFrame withPointer:NULL];
			}
		}
		
		[self.frameBuffer compact];
	}
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
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Audio Processing

-(NSInteger)session:(SPSpotifySession *)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat {
	
	@synchronized(frameBuffer) {
		
		if (frameCount == 0) {
			[self clearAudioBuffer];
			return 0; // Audio discontinuity!
		}
		
		if ([self.frameBuffer count] >= kMaximumFramesInBuffer) {
			return 0;
		}
		
        NSUInteger frameByteSize = sizeof(sint16) * audioFormat->channels;
		NSUInteger dataLength = frameCount * frameByteSize;
        
        for (NSUInteger chunkStart = 0; chunkStart < dataLength; chunkStart += frameByteSize) {
			void *frame = malloc(frameByteSize);
			memcpy(frame, (audioFrames + chunkStart), frameByteSize);
			[self.frameBuffer addPointer:frame];
        }
	}
	
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
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	AudioBuffer *leftBuffer = &(ioData->mBuffers[0]);
	AudioBuffer *rightBuffer = &(ioData->mBuffers[1]);

	@synchronized(frameBuffer) {
            
        if ([self.frameBuffer count] >= inNumberFrames) {
	
			float *leftChannelBuffer = leftBuffer->mData;
			float *rightChannelBuffer = rightBuffer->mData;
			
			double effectiveVolume = self.volume;
			
			for (NSUInteger currentFrame = 0; currentFrame < inNumberFrames; currentFrame++) {
				
				sint16 *frame = [self.frameBuffer pointerAtIndex:currentFrame];
				if (frame != NULL) {
					
					// Convert the frames from 16-bit signed integers to floating point, then apply the volume.
					leftChannelBuffer[currentFrame] = (frame[0]/(float)INT16_MAX) * effectiveVolume;
					rightChannelBuffer[currentFrame] = (frame[1]/(float)INT16_MAX) * effectiveVolume;

					free(frame);
					[self.frameBuffer replacePointerAtIndex:currentFrame withPointer:NULL];
				}
			}
			
			[self.frameBuffer compact];
			
			framesSinceLastUpdate += inNumberFrames;
			
			if (framesSinceLastUpdate >= 8820) {
				// Update 5 times per second.
				
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

				framesSinceLastUpdate = 0;
			}
			
        } else {
			leftBuffer->mDataByteSize = 0;
			rightBuffer->mDataByteSize = 0;
			*ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
		}
    }
    
	[pool drain];
    return noErr;
}

- (void)dealloc {

    [self removeObserver:self forKeyPath:@"playbackSession.isPlaying"];
	
	[self clearAudioBuffer];
	self.frameBuffer = nil;
    self.currentTrack = nil;
	self.playbackContext = nil;
	[self.audioUnit stop];
	self.audioUnit = nil;
	self.playbackSession = nil;
	
    [super dealloc];
}

@end
