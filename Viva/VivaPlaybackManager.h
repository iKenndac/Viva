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

static NSString * const kVivaPlaybackManagerErrorDomain = @"com.spotify.viva.playback";
static NSUInteger const kVivaTrackFailedToPlayErrorCode = 100;
static NSUInteger const kVivaTrackTokenLostErrorCode = 200;
static NSString * const kVivaTrackContainerKey = @"trackContainer";

@interface EQBands : NSObject <NSCopying>

@property (nonatomic, readwrite) double band1;
@property (nonatomic, readwrite) double band2;
@property (nonatomic, readwrite) double band3;
@property (nonatomic, readwrite) double band4;
@property (nonatomic, readwrite) double band5;
@property (nonatomic, readwrite) double band6;
@property (nonatomic, readwrite) double band7;
@property (nonatomic, readwrite) double band8;
@property (nonatomic, readwrite) double band9;
@property (nonatomic, readwrite) double band10;

@end

@class VivaPlaybackManager;

@protocol VivaPlaybackManagerDelegate <NSObject>

-(void)playbackManager:(VivaPlaybackManager *)manager didEncounterPlaybackError:(NSError *)error;

@end

@protocol VivaPlaybackManagerDataSource <NSObject>

-(BOOL)playbackManager:(VivaPlaybackManager *)manager requiresContextForContextlessPlayRequest:(id <VivaPlaybackContext> *)context;

@end

@interface VivaPlaybackManager : NSObject <SPSessionPlaybackDelegate>

-(id)initWithPlaybackSession:(SPSession *)aSession;

@property (readonly, strong) id <VivaPlaybackContext> playbackContext;
@property (readwrite) NSTimeInterval currentTrackPosition;
@property (readonly, strong) SPTrack *currentTrack;
@property (readonly, strong) id <VivaTrackContainer> currentTrackContainer;
@property (readonly, strong) SPSession *session;
@property (readonly, strong) id <SPSessionPlaybackProvider> currentPlaybackProvider;
@property (readwrite) double volume;
@property (readwrite) BOOL loopPlayback;
@property (readwrite) BOOL shufflePlayback;

-(NSString *)playPauseToggleMenuText;

@property (readonly) BOOL canSkipToNextTrack;
@property (readonly) BOOL canSkipToPreviousTrack;

@property (readwrite, assign) __unsafe_unretained id <VivaPlaybackManagerDataSource> dataSource;
@property (readwrite, nonatomic, assign) __unsafe_unretained id <VivaPlaybackManagerDelegate> delegate;

@property (readonly, strong) NSArray *leftLevels;
@property (readonly, strong) NSArray *rightLevels;

-(void)seekToTrackPosition:(NSTimeInterval)newPosition;

-(void)skipToNextTrackInCurrentContext:(BOOL)clearExistingAudioBuffers;
-(void)skipToPreviousTrackInCurrentContext:(BOOL)clearExistingAudioBuffers;

// EQ

@property (readwrite, nonatomic, strong) EQBands *eqBands;

@end
