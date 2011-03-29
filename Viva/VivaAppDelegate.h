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
#import "CoCA.h"

@interface VivaAppDelegate : NSObject <NSApplicationDelegate, SPSpotifySessionDelegate, CoCAAudioUnitRenderDelegate> {
@private
    NSWindow *window;
    SPSpotifySession *session;
	LoginWindowController *loginWindowController;
	MainWindowController *mainWindowController;
	NSData *audioData;
	CoCAAudioUnit *unit;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain, readwrite) SPSpotifySession *session; 
@property (retain, readwrite) NSData *audioData;

@end
