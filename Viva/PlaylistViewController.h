//
//  PlaylistViewController.h
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaInternalURLManager.h"

@interface PlaylistViewController : NSViewController <VivaViewController> {
@private

	SPSpotifyPlaylist *playlist;
    
	NSTableView *trackTable;
	NSArrayController *tracksArrayController;
}

-(id)initWithPlaylist:(SPSpotifyPlaylist *)aPlaylist;

@property (assign) IBOutlet NSArrayController *tracksArrayController;
@property (assign) IBOutlet NSTableView *trackTable;
@property (nonatomic, readonly, retain) SPSpotifyPlaylist *playlist;

-(IBAction)playTrack:(id)sender;

@end
