//
//  PlaylistViewController.h
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VivaPlaybackContextViewController.h"

@interface PlaylistViewController : VivaPlaybackContextViewController {
@private

	SPSpotifyPlaylist *playlist;
    
	NSTableView *trackTable;
	NSArrayController *trackContainerArrayController;
	BOOL sortAscending;
	NSArray *trackContainers;
}

@property (assign) IBOutlet NSArrayController *trackContainerArrayController;
@property (assign) IBOutlet NSTableView *trackTable;
@property (nonatomic, readonly, retain) SPSpotifyPlaylist *playlist;
@property (nonatomic, readonly, retain) NSArray *trackContainers;

-(IBAction)playTrack:(id)sender;

@end
