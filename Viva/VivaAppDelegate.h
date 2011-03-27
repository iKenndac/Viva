//
//  VivaAppDelegate.h
//  Viva
//
//  Created by Daniel Kennett on 3/7/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface VivaAppDelegate : NSObject <NSApplicationDelegate, SPSpotifySessionDelegate> {
@private
    NSWindow *window;
    SPSpotifySession *session;
    NSTextField *usernameField;
    NSSecureTextField *passwordField;
    NSWindow *loginSheet;
}

@property (assign) IBOutlet NSWindow *loginSheet;
@property (assign) IBOutlet NSWindow *window;
@property (retain, readwrite) SPSpotifySession *session; 
@property (assign) IBOutlet NSTextField *usernameField;
@property (assign) IBOutlet NSSecureTextField *passwordField;

- (IBAction)login:(id)sender;
- (IBAction)cancelLogin:(id)sender;


@end
