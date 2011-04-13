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
#import "SPMediaKeyTap.h"

@interface VivaAppDelegate : NSObject <NSApplicationDelegate, SPSpotifySessionDelegate> {
@private
    NSWindow *window;
    SPSpotifySession *session;
	LoginWindowController *loginWindowController;
	MainWindowController *mainWindowController;
	VivaPlaybackManager *playbackManager;
	NSMenu *dockMenu;
	SPMediaKeyTap *mediaKeyHandler;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain, readonly) SPSpotifySession *session; 
@property (retain, readonly) VivaPlaybackManager *playbackManager; 
@property (assign) IBOutlet NSMenu *dockMenu;
@property (retain, readonly) SPMediaKeyTap *mediaKeyHandler; 

// For Applescript, Dock menu, etc
-(IBAction)performNextTrackAction:(id)sender;
-(IBAction)performSeekForwardABitAction:(id)sender;
-(IBAction)performPreviousTrackAction:(id)sender;
-(IBAction)performSeekBackwardABitAction:(id)sender;
-(IBAction)performPlayPauseAction:(id)sender;
-(IBAction)performVolumeUpAction:(id)sender;
-(IBAction)performVolumeDownAction:(id)sender;

@end
