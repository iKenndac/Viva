//
//  VivaSortableTrackListController.h
//  Viva
//
//  Created by Daniel Kennett on 4/22/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VivaPlaybackContextViewController.h"

@interface VivaSortableTrackListController : VivaPlaybackContextViewController {
@private
	NSTableView *trackTable;
	NSArrayController *trackContainerArrayController;
	BOOL sortAscending;
}

@property (assign) IBOutlet NSArrayController *trackContainerArrayController;
@property (assign) IBOutlet NSTableView *trackTable;

@end
