//
//  PlaylistsViewController.h
//  Viva
//
//  Created by Daniel Kennett on 23/08/2012.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SPBackgroundColorView.h"
#import "VivaSortableTrackListController.h"
#import "VivaInternalURLManager.h"

@interface PlaylistsViewController : VivaSortableTrackListController <NSOutlineViewDelegate>

@property (weak) IBOutlet SPBackgroundColorView *backgroundColorView;
@property (weak) IBOutlet SPBackgroundColorView *leftColumnColorView;
@property (strong) IBOutlet NSTreeController *playlistTreeController;

@end
