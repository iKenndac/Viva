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

@interface VivaPlaybackManager : NSObject <CoCAAudioUnitRenderDelegate> {
@private
    id <VivaPlaybackContext> playbackContext;
	NSMutableData *audioBuffer;
	CoCAAudioUnit *audioUnit;
}

@property (readonly, retain) id <VivaPlaybackContext> playbackContext;

-(void)sessionDidLosePlayToken:(SPSpotifySession *)aSession;
-(void)sessionDidEndPlayback:(SPSpotifySession *)aSession;
-(NSInteger)session:(SPSpotifySession *)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat;

@end
