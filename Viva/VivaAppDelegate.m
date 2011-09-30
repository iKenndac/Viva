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
#import "NSObject+Spotify.h"
#import "SearchResultsViewController.h"
#import "AlbumViewController.h"
#import "ArtistViewController.h"
#import "EMKeychainItem.h"
#import "StarredViewController.h"

@interface VivaAppDelegate()

@property (retain, readwrite) VivaPlaybackManager *playbackManager; 
@property (retain, readwrite) SPMediaKeyTap *mediaKeyHandler;

@end

@implementation VivaAppDelegate

@synthesize window;
@synthesize playbackManager;
@synthesize dockMenu;
@synthesize mediaKeyHandler;

-(SPSession *)session {
	return [SPSession sharedSession];
}

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers], kMediaKeyUsingBundleIdentifiersDefaultsKey,
															 nil]];
	
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[PlaylistViewController class] forURLScheme:@"spotify:user"];
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[SearchResultsViewController class] forURLScheme:@"spotify:search"];
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[AlbumViewController class] forURLScheme:@"spotify:album"];
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[ArtistViewController class] forURLScheme:@"spotify:artist"];
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[StarredViewController class] forURLScheme:@"spotify:internal:starred"];

	NSError *error = nil;
	[SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"libspotify_appkey" ofType:@"key"]]
											   userAgent:kVivaLibSpotifyUserAgentName
												   error:&error];
	
	if (error != nil) {
		NSRunAlertPanel(@"Initializing CocoaLibSpotify failed!", 
						[NSString stringWithFormat:@"%@", error], 
						@"Quit",
						@"",
						@"");
		[NSApp terminate:self];
	}
	
    [SPSession sharedSession].delegate = self;
    
	mainWindowController = [[MainWindowController alloc] init];
	loginWindowController = [[LoginWindowController alloc] init];
	self.playbackManager = [[[VivaPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]] autorelease];
	
	if ([SPMediaKeyTap usesGlobalMediaKeyTap]) {
		self.mediaKeyHandler = [[[SPMediaKeyTap alloc] initWithDelegate:self] autorelease];
		[self.mediaKeyHandler startWatchingMediaKeys];
	} else {
		NSLog(@"Media key monitoring disabled because CGEventTap + gdb = pain");
	}
	
	[NSApp setDockMenu:self.dockMenu];
	[loginWindowController showWindow:nil];

}

-(BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
	if (mainWindowController != nil) {
		[mainWindowController showWindow:nil];
	}
	return YES;
}

-(void)applicationWillTerminate:(NSNotification *)notification {
	
	[[SPSession sharedSession] logout];
}

#pragma mark -

-(void)logOut {
	EMKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService:kVivaKeychainServiceName
																		   withUsername:[[NSUserDefaults standardUserDefaults] valueForKey:kVivaLastUserNameUserDefaultsKey]];
	[keychainItem removeFromKeychain];
	
	[[SPSession sharedSession] logout];
	[mainWindowController close];
	[loginWindowController reset];
	[loginWindowController showWindow:nil];
}

#pragma mark -

-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event {

	int keyCode = (([event data1] & 0xFFFF0000) >> 16);
	int keyFlags = ([event data1] & 0x0000FFFF);
	int keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA;
	int keyRepeat = (keyFlags & 0x1);
	keyRepeat = 0; // Seeking doesn't work properly yet!
	if (keyState == 1) {
		switch (keyCode) {
			case NX_KEYTYPE_PLAY:
				if (!keyRepeat) {
					[self performPlayPauseAction:nil];
				}
				return;
			case NX_KEYTYPE_FAST:
				if (!keyRepeat) {
					[self performNextTrackAction:nil];
				} else {
					[self performSeekForwardABitAction:nil];
				}
				return;
			case NX_KEYTYPE_REWIND:
				if (!keyRepeat) {
					[self performPreviousTrackAction:nil];
				} else {
					[self performSeekBackwardABitAction:nil];
				}
				return;
		}
	}
}


// For Applescript, Dock menu, etc
-(IBAction)performNextTrackAction:(id)sender {
	if (self.playbackManager.currentTrack != nil) {
		[self.playbackManager skipToNextTrackInCurrentContext:YES];
	}
}

-(IBAction)performSeekForwardABitAction:(id)sender {
	if (self.playbackManager.currentTrack != nil) {
		[self.playbackManager seekToTrackPosition:MIN(self.playbackManager.currentTrackPosition + kSeekABitInterval, self.playbackManager.currentTrack.duration)];
	}
}

-(IBAction)performPreviousTrackAction:(id)sender {
	if (self.playbackManager.currentTrack != nil) {
		if (self.playbackManager.currentTrackPosition > kSkipBackThreshold) {
			[self.playbackManager seekToTrackPosition:0.0];
		} else if ([self.playbackManager canSkipToPreviousTrack]) {
			[self.playbackManager skipToPreviousTrackInCurrentContext:YES];
		} else {
			NSBeep();
		}
	}
}

-(IBAction)performSeekBackwardABitAction:(id)sender {
	if (self.playbackManager.currentTrack != nil) {
		[self.playbackManager seekToTrackPosition:MAX(self.playbackManager.currentTrackPosition - kSeekABitInterval, 0.0)];
	}
}

-(IBAction)performPlayPauseAction:(id)sender {
	if (self.playbackManager.currentTrack != nil) {
		self.playbackManager.playbackSession.playing = !self.playbackManager.playbackSession.playing;
	}
}

-(IBAction)performVolumeUpAction:(id)sender {
	self.playbackManager.volume = MIN(1.0, self.playbackManager.volume + kVolumeStepSize);
}

-(IBAction)performVolumeDownAction:(id)sender {
	self.playbackManager.volume = MAX(0.0, self.playbackManager.volume - kVolumeStepSize);
}

#pragma mark -

-(void)sessionDidLoginSuccessfully:(SPSession *)aSession; {

	[mainWindowController showWindow:nil];
	[[loginWindowController window] orderOut:nil]; 
	loginWindowController.isLoggingIn = NO;
}

-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error; {
    
    [NSApp presentError:error
         modalForWindow:[loginWindowController window]
               delegate:nil
     didPresentSelector:nil
            contextInfo:nil];
	
	loginWindowController.isLoggingIn = NO;
}
    
-(void)sessionDidLogOut:(SPSession *)aSession; {}

-(void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error; {}
-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage; {}
-(void)sessionDidChangeMetadata:(SPSession *)aSession; {}

-(void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {}

-(void)dealloc {
	[playbackManager release];
	[mainWindowController release];
	[loginWindowController release];
	[self.mediaKeyHandler stopWatchingMediaKeys];
	self.mediaKeyHandler = nil;
	
	[super dealloc];
}

@end
