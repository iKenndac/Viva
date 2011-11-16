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

@interface VivaPlaybackManager : NSObject <SPSessionPlaybackDelegate>

-(id)initWithPlaybackSession:(SPSession *)aSession;

@property (readonly, strong) id <VivaPlaybackContext> playbackContext;
@property (readwrite) NSTimeInterval currentTrackPosition;
@property (readonly, strong) SPTrack *currentTrack;
@property (readonly, strong) id <VivaTrackContainer> currentTrackContainer;
@property (readonly, strong) SPSession *playbackSession;
@property (readwrite) double volume;
@property (readwrite) BOOL loopPlayback;
@property (readwrite) BOOL shufflePlayback;

@property (readonly) BOOL canSkipToNextTrack;
@property (readonly) BOOL canSkipToPreviousTrack;

@property (readwrite, assign) __unsafe_unretained id <VivaPlaybackManagerDataSource> dataSource;

@property (readonly, strong) NSArray *leftLevels;
@property (readonly, strong) NSArray *rightLevels;

-(void)seekToTrackPosition:(NSTimeInterval)newPosition;

-(void)skipToNextTrackInCurrentContext:(BOOL)clearExistingAudioBuffers;
-(void)skipToPreviousTrackInCurrentContext:(BOOL)clearExistingAudioBuffers;

@end
