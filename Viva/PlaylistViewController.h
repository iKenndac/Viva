//
//  PlaylistViewController.h
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VivaSortableTrackListController.h"
#import "SPPlaylistDelegateProxy.h"

@interface PlaylistViewController : VivaSortableTrackListController <SPPlaylistDelegate> {
@private

	SPPlaylist *playlist;
	SPPlaylistDelegateProxy *playlistProxy;
}

@property (nonatomic, readonly, strong) SPPlaylist *playlist;
@property (nonatomic, readonly, strong) SPPlaylistDelegateProxy *playlistProxy;

@end

