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
#import "CoCA.h"
#import "SPCircularBuffer.h"

@interface VivaPlaybackManager : NSObject <CoCAAudioUnitRenderDelegate, SPSpotifySessionPlaybackDelegate> {
@private
    id <VivaPlaybackContext> playbackContext;
	id <VivaTrackContainer> currentTrackContainer;
	CoCAAudioUnit *audioUnit;
	NSTimeInterval currentTrackPosition;
	SPSpotifySession *playbackSession;
	SPCircularBuffer *audioBuffer;
	double volume;
	BOOL loopPlayback;
	BOOL hasPreCachedNextTrack;
}

-(id)initWithPlaybackSession:(SPSpotifySession *)aSession;

@property (readonly, retain) id <VivaPlaybackContext> playbackContext;
@property (readwrite) NSTimeInterval currentTrackPosition;
@property (readonly, retain) SPSpotifyTrack *currentTrack;
@property (readonly, retain) id <VivaTrackContainer> currentTrackContainer;
@property (readonly, retain) SPSpotifySession *playbackSession;
@property (readwrite) double volume;
@property (readwrite) BOOL loopPlayback;

@property (readonly) BOOL canSkipToNextTrack;
@property (readonly) BOOL canSkipToPreviousTrack;

-(void)seekToTrackPosition:(NSTimeInterval)newPosition;

-(void)skipToNextTrackInCurrentContext:(BOOL)clearExistingAudioBuffers;
-(void)skipToPreviousTrackInCurrentContext:(BOOL)clearExistingAudioBuffers;

@end
