//
//  VivaPlaybackManager.h
//  Viva
//
//  Created by Daniel Kennett on 3/30/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VivaPlaybackContext.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "SPCircularBuffer.h"
#import <Accelerate/Accelerate.h>
#import <CoreAudio/CoreAudio.h>
#import <AudioUnit/AudioUnit.h>

@class VivaPlaybackManager;

@protocol VivaPlaybackManagerDataSource <NSObject>

-(BOOL)playbackManager:(VivaPlaybackManager *)manager requiresContextForContextlessPlayRequest:(id <VivaPlaybackContext> *)context;

@end

@interface VivaPlaybackManager : NSObject <SPSessionPlaybackDelegate> {
@private
    id <VivaPlaybackContext> playbackContext;
	id <VivaTrackContainer> currentTrackContainer;
	NSTimeInterval currentTrackPosition;
	SPSession *playbackSession;
	SPCircularBuffer *audioBuffer;
	double volume;
	BOOL loopPlayback;
    BOOL shufflePlayback;
	BOOL hasPreCachedNextTrack;
	NSMethodSignature *incrementTrackPositionMethodSignature;
	NSInvocation *incrementTrackPositionInvocation;
	
    NSMutableArray *shuffledPool;
    NSMutableArray *shufflePastHistory;
    NSMutableArray *shuffleFutureHistory;
    
    AudioUnit outputAudioUnit;
    
    __weak id <VivaPlaybackManagerDataSource> dataSource;
    
	// vDSP
	FFTSetupD fft_weights;
	double *leftChannelMagnitudes;
	double *rightChannelMagnitudes;
	
	NSArray *leftLevels;
	NSArray *rightLevels;
}

-(id)initWithPlaybackSession:(SPSession *)aSession;

@property (readonly, retain) id <VivaPlaybackContext> playbackContext;
@property (readwrite) NSTimeInterval currentTrackPosition;
@property (readonly, retain) SPTrack *currentTrack;
@property (readonly, retain) id <VivaTrackContainer> currentTrackContainer;
@property (readonly, retain) SPSession *playbackSession;
@property (readwrite) double volume;
@property (readwrite) BOOL loopPlayback;
@property (readwrite) BOOL shufflePlayback;

@property (readonly) BOOL canSkipToNextTrack;
@property (readonly) BOOL canSkipToPreviousTrack;

@property (readwrite, assign) __weak id <VivaPlaybackManagerDataSource> dataSource;

@property (readonly, retain) NSArray *leftLevels;
@property (readonly, retain) NSArray *rightLevels;

-(void)seekToTrackPosition:(NSTimeInterval)newPosition;

-(void)skipToNextTrackInCurrentContext:(BOOL)clearExistingAudioBuffers;
-(void)skipToPreviousTrackInCurrentContext:(BOOL)clearExistingAudioBuffers;

@end
