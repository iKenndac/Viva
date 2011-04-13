//
//  VivaAppDelegate.m
//  Viva
//
//  Created by Daniel Kennett on 3/7/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaAppDelegate.h"
#import "PlaylistViewController.h"
#import "VivaInternalURLManager.h"
#import "Constants.h"

@interface VivaAppDelegate()

@property (retain, readwrite) SPSpotifySession *session; 
@property (retain, readwrite) VivaPlaybackManager *playbackManager; 

@end

@implementation VivaAppDelegate

@synthesize window;
@synthesize session;
@synthesize playbackManager;
@synthesize dockMenu;

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
	
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[PlaylistViewController class] forURLScheme:@"spotify:user"];
	
    self.session = [SPSpotifySession sessionWithApplicationKey:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"libspotify_appkey"
																															  ofType:@"key"]]
													 userAgent:@"CocoaLibSpotify"
														 error:nil];
    self.session.delegate = self;
    
	mainWindowController = [[MainWindowController alloc] init];
	loginWindowController = [[LoginWindowController alloc] init];
	self.playbackManager = [[[VivaPlaybackManager alloc] initWithPlaybackSession:self.session] autorelease];
	self.session.playbackDelegate = playbackManager;
	
	[NSApp setDockMenu:self.dockMenu];
	[loginWindowController showWindow:nil];

}

-(BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
	if (mainWindowController != nil) {
		[mainWindowController showWindow:nil];
	}
	return YES;
}

#pragma mark -

// For Applescript, Dock menu, etc
-(IBAction)performNextTrackAction:(id)sender {
	if (self.playbackManager.currentTrack != nil) {
		[self.playbackManager skipToNextTrackInCurrentContext:YES];
	}
}

-(IBAction)performPreviousTrackAction:(id)sender {
	if (self.playbackManager.currentTrack != nil) {
		[self.playbackManager skipToPreviousTrackInCurrentContext:YES];
	}
}

-(IBAction)performPlayPauseAction:(id)sender {
	if (self.playbackManager.currentTrack != nil) {
		self.playbackManager.playbackSession.isPlaying = !self.playbackManager.playbackSession.isPlaying;
	}
}

-(IBAction)performVolumeUpAction:(id)sender {
	self.playbackManager.volume = MIN(1.0, self.playbackManager.volume + kVolumeStepSize);
}

-(IBAction)performVolumeDownAction:(id)sender {
	self.playbackManager.volume = MAX(0.0, self.playbackManager.volume - kVolumeStepSize);
}

#pragma mark -

-(void)sessionDidLoginSuccessfully:(SPSpotifySession *)aSession; {

	[mainWindowController showWindow:nil];
	[[loginWindowController window] orderOut:nil]; 
	loginWindowController.isLoggingIn = NO;
}

-(void)session:(SPSpotifySession *)aSession didFailToLoginWithError:(NSError *)error; {
    
    [NSApp presentError:error
         modalForWindow:[loginWindowController window]
               delegate:nil
     didPresentSelector:nil
            contextInfo:nil];
	
	loginWindowController.isLoggingIn = NO;
}
    
-(void)sessionDidLogOut:(SPSpotifySession *)aSession; {}

-(void)session:(SPSpotifySession *)aSession didEncounterNetworkError:(NSError *)error; {}
-(void)session:(SPSpotifySession *)aSession didLogMessage:(NSString *)aMessage; {}
-(void)sessionDidChangeMetadata:(SPSpotifySession *)aSession; {}

-(void)session:(SPSpotifySession *)aSession recievedMessageForUser:(NSString *)aMessage; {}

-(void)dealloc {
	[playbackManager release];
	[mainWindowController release];
	[loginWindowController release];
	
	[super dealloc];
}

@end
