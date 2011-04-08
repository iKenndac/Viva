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

#define kMaximumFramesInBuffer 44100 // 1 Second

@implementation VivaPlaybackManager

- (id)initWithPlaybackSession:(SPSpotifySession *)aSession {
    self = [super init];
    if (self) {
        // Initialization code here.
		
		self.volume = 1.0;
		self.playbackSession = aSession;
        self.audioChunks = [NSMutableArray arrayWithCapacity:kMaximumFramesInBuffer * 2];
        
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
@synthesize volume;

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
		
		if ([self.audioChunks count] >= kMaximumFramesInBuffer) {
			return 0;
		}
		
        NSUInteger frameByteSize = sizeof(sint16) * audioFormat->channels;
		NSUInteger dataLength = frameCount * frameByteSize;
        
        for (NSUInteger chunkStart = 0; chunkStart < dataLength; chunkStart += frameByteSize) {
            [self.audioChunks addObject:[NSData dataWithBytes:(audioFrames + chunkStart) length:frameByteSize]];
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
    NSArray *frames = nil;
	
	@synchronized(audioChunks) {
            
        if ([self.audioChunks count] >= inNumberFrames) {
			NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, inNumberFrames)];
			frames = [self.audioChunks objectsAtIndexes:indexSet];
            [self.audioChunks removeObjectsAtIndexes:indexSet];
        }
    }
	
    AudioBuffer *leftBuffer = &(ioData->mBuffers[0]);
    AudioBuffer *rightBuffer = &(ioData->mBuffers[1]); 
    
    if (frames == nil) {
        leftBuffer->mDataByteSize = 0;
        rightBuffer->mDataByteSize = 0;
        *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
        [pool drain];
        return noErr;
    }
    
    leftBuffer->mDataByteSize = inNumberFrames * 4;
    rightBuffer->mDataByteSize = inNumberFrames * 4;
    
    float *leftChannelBuffer = leftBuffer->mData;
    float *rightChannelBuffer = rightBuffer->mData;
	
	double effectiveVolume = self.volume;
    
    for(int currentFrame = 0; currentFrame < inNumberFrames; currentFrame++) {
        
		NSData *thisFrame = [frames objectAtIndex:currentFrame];
		sint16 *rawFrames = (sint16 *)[thisFrame bytes];
		
        sint16 leftSample = rawFrames[0];
        float destinationLeftSample = leftSample/(float)INT16_MAX;
        
        sint16 rightSample = rawFrames[1];
        float destinationRightSample = rightSample/(float)INT16_MAX;
        
        leftChannelBuffer[currentFrame] = destinationLeftSample * effectiveVolume;
        rightChannelBuffer[currentFrame] = destinationRightSample * effectiveVolume;
    }	
    
    self.currentTrackPosition += (double)inNumberFrames / 44100;
    
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
