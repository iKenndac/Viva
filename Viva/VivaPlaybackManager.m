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

@property (retain, readwrite) NSMutableData *audioBuffer;
@property (retain, readwrite) CoCAAudioUnit *audioUnit;
@property (retain, readwrite) id <VivaPlaybackContext> playbackContext;
@property (readwrite, retain) SPSpotifyTrack *currentTrack;
@property (readwrite, retain) SPSpotifySession *playbackSession;

@end

@implementation VivaPlaybackManager

- (id)initWithPlaybackSession:(SPSpotifySession *)aSession {
    self = [super init];
    if (self) {
        // Initialization code here.
		
		self.playbackSession = aSession;
		self.audioBuffer = [NSMutableData data];
		
		// Playback
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(playTrack:)
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

-(void)playTrack:(NSNotification *)aNotification {
	
	[self.playbackSession setIsPlaying:NO];
	[self.playbackSession unloadPlayback];
	[self.audioUnit stop];
	self.audioUnit = nil;
	
	@synchronized(audioBuffer) {
		[self.audioBuffer setLength:0];
	}
	
	self.currentTrackPosition = 0.0;
	
	SPSpotifyTrack *track = [aNotification object];
	self.currentTrack = track;
	[self.playbackSession playTrack:track];	
}

-(void)seekToTrackPosition:(NSTimeInterval)newPosition {
	if (newPosition <= self.currentTrack.duration) {
		[self.playbackSession seekPlaybackToOffset:newPosition];
		self.currentTrackPosition = newPosition;
	}	
}

#pragma mark -
#pragma mark Playback Callbacks

-(void)sessionDidLosePlayToken:(SPSpotifySession *)aSession {}

-(void)sessionDidEndPlayback:(SPSpotifySession *)aSession {
	[self.audioUnit stop];
	self.audioUnit = nil;
	self.currentTrackPosition = 0;
	self.currentTrack = nil;
}

#pragma mark Audio Processing

#define kMaximumBytesInBuffer 1024 * 256

-(NSInteger)session:(SPSpotifySession *)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat {
	
	@synchronized(audioBuffer) {
		
		if (frameCount == 0) {
			[self.audioBuffer setData:[NSData data]];
			return 0; // Audio discontinuity!
		}
		
		if ([self.audioBuffer length] >= kMaximumBytesInBuffer) {
			return 0;
		}
		
		[self.audioBuffer appendBytes:audioFrames length:frameCount * sizeof(sint16) * audioFormat->channels];
	}
	
	if (self.audioUnit == nil) {
		self.audioUnit = [CoCAAudioUnit defaultOutputUnit];
		[self.audioUnit setRenderDelegate:self];
		[self.audioUnit setup];
		[self.audioUnit start];
	}
	
	return frameCount;
}

-(OSStatus)audioUnit:(CoCAAudioUnit*)audioUnit
     renderWithFlags:(AudioUnitRenderActionFlags*)ioActionFlags
                  at:(const AudioTimeStamp*)inTimeStamp
               onBus:(UInt32)inBusNumber
          frameCount:(UInt32)inNumberFrames
           audioData:(AudioBufferList *)ioData;
{
	
	@synchronized(audioBuffer) {
		// Core Audio generally expects audio data to be in native-endian 32-bit floating-point linear PCM format.
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSUInteger sourceByteCount = inNumberFrames * sizeof(SInt16) * ioData->mNumberBuffers;
		const void *sourceBytes = [self.audioBuffer bytes];
		sint16 *sourceFrames = (sint16 *)sourceBytes;
		NSUInteger actualNumberOfFrames = inNumberFrames;
		
		AudioBuffer *leftBuffer = &(ioData->mBuffers[0]);
		AudioBuffer *rightBuffer = &(ioData->mBuffers[1]); 
		
		if ([self.audioBuffer length] < sourceByteCount) {
			NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Underrun!");
			sourceByteCount = [self.audioBuffer length];
			actualNumberOfFrames = [self.audioBuffer length] / 4;
		}
		
		float *leftChannelBuffer = (float*)(leftBuffer->mData);
		float *rightChannelBuffer = (float*)(rightBuffer->mData);
		
		for(int sample = 0; sample < actualNumberOfFrames; sample++) {
			
			float leftSample = (float)(sourceFrames[sample * 2]);
			float destinationLeftSample = leftSample/(float)INT16_MAX;
			
			float rightSample = (float)(sourceFrames[(sample * 2) + 1]);
			float destinationRightSample = rightSample/(float)INT16_MAX;
			
			leftChannelBuffer[sample] = destinationLeftSample;
			rightChannelBuffer[sample] = destinationRightSample;
		}	
		
		leftBuffer->mDataByteSize = (UInt32)actualNumberOfFrames * 4;
		rightBuffer->mDataByteSize = (UInt32)actualNumberOfFrames * 4;
		
		self.currentTrackPosition += (double)actualNumberOfFrames / 44100;
		
		[self.audioBuffer replaceBytesInRange:NSMakeRange(0, sourceByteCount)
								  withBytes:NULL
									 length:0];
		[pool drain];
		return noErr;
		
	}
}

- (void)dealloc {

	self.currentTrack = nil;
	self.playbackContext = nil;
	[self.audioUnit stop];
	self.audioUnit = nil;
	self.audioBuffer = nil;
	self.playbackSession = nil;
	
    [super dealloc];
}

@end
