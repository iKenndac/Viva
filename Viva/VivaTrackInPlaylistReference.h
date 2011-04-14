//
//  VivaPlayableTrack.h
//  Viva
//
//  Created by Daniel Kennett on 4/14/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaPlaybackContext.h"

@interface VivaTrackInPlaylistReference : NSObject <VivaTrackContainer> {
@private
    NSString *uniqueId;
	__weak SPSpotifyTrack *track;
	__weak SPSpotifyPlaylist *playlist;
}

-(id)initWithTrack:(SPSpotifyTrack *)aTrack inPlaylist:(SPSpotifyPlaylist *)aPlaylist;

@property (copy, readonly) NSString *uniqueId;
@property (assign, readonly) __weak SPSpotifyTrack *track;
@property (assign, readonly) __weak SPSpotifyPlaylist *playlist;

@end
