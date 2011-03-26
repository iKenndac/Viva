//
//  VivaPlaylistController.h
//  Viva
//
//  Created by Daniel Kennett on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface VivaPlaylistController : NSObject {
@private
    __weak SPSpotifyPlaylist *playlist;
}

- (id)initWithPlaylist:(__weak SPSpotifyPlaylist *)aPlaylist;

@property (readonly, assign, nonatomic) __weak SPSpotifyPlaylist *playlist;

@end
