//
//  AlbumViewController.h
//  Viva
//
//  Created by Daniel Kennett on 4/24/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VivaSortableTrackListController.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface AlbumViewController : VivaSortableTrackListController {
@private
    SPAlbumBrowse *albumBrowse;
}

@property (nonatomic, readonly, strong) SPAlbumBrowse *albumBrowse;

@end
