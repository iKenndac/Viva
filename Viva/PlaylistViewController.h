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
}

-(id)initWithPlaylist:(SPSpotifyPlaylist *)aPlaylist;

@property (assign) IBOutlet NSTableView *trackTable;
@property (nonatomic, readonly, retain) SPSpotifyPlaylist *playlist;

@end
