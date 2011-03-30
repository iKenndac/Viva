//
//  VivaPlaybackContext.h
//  Viva
//
//  Created by Daniel Kennett on 3/30/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@protocol VivaPlaybackContext <NSObject>

// This must be KVO compliant, for e.g. when the user filters the playlist
-(NSArray *)tracksForPlayback;

-(void)setPlayingTrack:(SPSpotifyTrack *)playingTrack;

@end
