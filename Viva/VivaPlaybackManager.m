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

@property (retain, readwrite) NSMutableArray *audioChunks;
@property (retain, readwrite) CoCAAudioUnit *audioUnit;
@property (retain, readwrite) id <VivaPlaybackContext> playbackContext;
@property (readwrite, retain) SPSpotifyTrack *currentTrack;
@property (readwrite, retain) SPSpotifySession *playbackSession;

@end

#define kMaximumChunksInBuffer 400

@implementation VivaPlaybackManager

- (id)initWithPlaybackSession:(SPSpotifySession *)aSession {
    self = [super init];
    if (self) {
        // Initialization code here.
		
		self.playbackSession = aSession;
        self.audioChunks = [NSMutableArray arrayWithCapacity:kMaximumChunksInBuffer];
        
        [self addObserver:self
               forKeyPath:@"playbackSession.isPlaying"
                  options:0
                  context:nil];
		
		// Playback
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(playTrack:)
													 name:kTrackShouldBePlayedNotification
												   object:nil];
    }
    
    return self;
}

@synthesize audioChunks;
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
	
	@synchronized(audioChunks) {
		[self.audioChunks removeAllObjects];
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
	
	@synchronized(audioChunks) {
		
		if (frameCount == 0) {
			[self.audioChunks removeAllObjects];
			return 0; // Audio discontinuity!
		}
		
		if ([self.audioChunks count] >= kMaximumChunksInBuffer) {
			return 0;
		}
		
        // Core Audio wants 2048 bytes (512 frames) per channel per callback, and we get 2048 frames per LibSpotify push.
        
        NSData *audioData = [NSData dataWithBytes:audioFrames length:frameCount * sizeof(sint16) * audioFormat->channels];
        
        NSUInteger chunkSize = 512 * sizeof(sint16) * audioFormat->channels;
        
        for (NSUInteger chunkStart = 0; chunkStart < [audioData length]; chunkStart += chunkSize) {
            [self.audioChunks addObject:[audioData subdataWithRange:NSMakeRange(chunkStart, chunkSize)]];
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

-(OSStatus)audioUnit:(CoCAAudioUnit*)audioUnit
     renderWithFlags:(AudioUnitRenderActionFlags*)ioActionFlags
                  at:(const AudioTimeStamp*)inTimeStamp
               onBus:(UInt32)inBusNumber
          frameCount:(UInt32)inNumberFrames
           audioData:(AudioBufferList *)ioData;
{
	
    // Core Audio generally expects audio data to be in native-endian 32-bit floating-point linear PCM format.
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSData *data = nil;
    
	@synchronized(audioChunks) {
            
        if ([self.audioChunks count] > 0) {
            data = [[self.audioChunks objectAtIndex:0] retain];
            [self.audioChunks removeObjectAtIndex:0];
        }
    }
    
    AudioBuffer *leftBuffer = &(ioData->mBuffers[0]);
    AudioBuffer *rightBuffer = &(ioData->mBuffers[1]); 
    
    if (data == nil) {
        memset(leftBuffer, 0, leftBuffer->mDataByteSize);
        memset(rightBuffer, 0, rightBuffer->mDataByteSize);
        *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
        [pool drain];
        return noErr;
    }
    
    const void *sourceBytes = [data bytes];
    sint16 *sourceFrames = (sint16 *)sourceBytes;
    NSUInteger actualNumberOfFramesPerChannel = [data length] / 4; // 2 channels @ 16 bits per channel 
    
    leftBuffer->mDataByteSize = (UInt32)actualNumberOfFramesPerChannel * 4;
    rightBuffer->mDataByteSize = (UInt32)actualNumberOfFramesPerChannel * 4;
    
    float *leftChannelBuffer = (float*)(leftBuffer->mData);
    float *rightChannelBuffer = (float*)(rightBuffer->mData);
    
    for(int sample = 0; sample < actualNumberOfFramesPerChannel; sample++) {
        
        float leftSample = (float)(sourceFrames[sample * 2]);
        float destinationLeftSample = leftSample/(float)INT16_MAX;
        
        float rightSample = (float)(sourceFrames[(sample * 2) + 1]);
        float destinationRightSample = rightSample/(float)INT16_MAX;
        
        leftChannelBuffer[sample] = destinationLeftSample;
        rightChannelBuffer[sample] = destinationRightSample;
    }	
    
    self.currentTrackPosition += (double)actualNumberOfFramesPerChannel / 44100;
    
    [data release];
    [pool drain];
    return noErr;
}

- (void)dealloc {

    [self removeObserver:self forKeyPath:@"playbackSession.isPlaying"];
	
    self.currentTrack = nil;
	self.playbackContext = nil;
	[self.audioUnit stop];
	self.audioUnit = nil;
    self.audioChunks = nil;
	self.playbackSession = nil;
	
    [super dealloc];
}

@end
