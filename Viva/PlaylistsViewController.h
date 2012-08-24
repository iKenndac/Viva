//
//  PlaylistsViewController.h
//  Viva
//
//  Created by Daniel Kennett on 23/08/2012.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SPBackgroundColorView.h"
#import "VivaInternalURLManager.h"

@interface PlaylistsViewController : NSViewController <VivaViewController, NSOutlineViewDelegate>

@property (weak) IBOutlet SPBackgroundColorView *backgroundColorView;
@property (weak) IBOutlet SPBackgroundColorView *leftColumnColorView;
@property (strong) IBOutlet NSTreeController *playlistTreeController;
@property (weak) IBOutlet NSView *containerViewContainer;
@property (weak) IBOutlet NSOutlineView *playlistsOutlineView;

@property (nonatomic, readwrite, strong) NSViewController <VivaViewController> *contentViewController;

-(IBAction)copySpotifyURI:(id)sender;

@end
