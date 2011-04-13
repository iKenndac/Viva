//
//  VivaAppDelegate.h
//  Viva
//
//  Created by Daniel Kennett on 3/7/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "LoginWindowController.h"
#import "MainWindowController.h"
#import "VivaPlaybackManager.h"

@interface VivaAppDelegate : NSObject <NSApplicationDelegate, SPSpotifySessionDelegate> {
@private
    NSWindow *window;
    SPSpotifySession *session;
	LoginWindowController *loginWindowController;
	MainWindowController *mainWindowController;
	VivaPlaybackManager *playbackManager;
	NSMenu *dockMenu;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain, readonly) SPSpotifySession *session; 
@property (retain, readonly) VivaPlaybackManager *playbackManager; 
@property (assign) IBOutlet NSMenu *dockMenu;

// For Applescript, Dock menu, etc
-(IBAction)performNextTrackAction:(id)sender;
-(IBAction)performPreviousTrackAction:(id)sender;
-(IBAction)performPlayPauseAction:(id)sender;

@end
