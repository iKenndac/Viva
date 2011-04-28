//
//  PlaylistViewController.h
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VivaSortableTrackListController.h"

@interface PlaylistViewController : VivaSortableTrackListController <SPPlaylistDelegate> {
@private

	SPPlaylist *playlist;
}

@property (nonatomic, readonly, retain) SPPlaylist *playlist;

@end
