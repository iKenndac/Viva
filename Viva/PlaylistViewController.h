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
	NSArrayController *tracksArrayController;
	BOOL sortAscending;
}

@property (assign) IBOutlet NSArrayController *tracksArrayController;
@property (assign) IBOutlet NSTableView *trackTable;
@property (nonatomic, readonly, retain) SPSpotifyPlaylist *playlist;

-(IBAction)playTrack:(id)sender;

@end
