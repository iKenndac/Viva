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

@implementation VivaAppDelegate

@synthesize window;
@synthesize session;

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
	
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[PlaylistViewController class] forURLScheme:@"spotify:user"];
	
    [self setSession:[SPSpotifySession sessionWithApplicationKey:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"libspotify_appkey"
                                                                                                                                ofType:@"key"]]
                                                       userAgent:@"CocoaLibSpotify"
                                                           error:nil]];
    [[self session] setDelegate:self];
    
	mainWindowController = [[MainWindowController alloc] init];
	loginWindowController = [[LoginWindowController alloc] init];
	[loginWindowController showWindow:nil];
	
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
-(void)sessionDidLosePlayToken:(SPSpotifySession *)aSession; {}
-(void)sessionDidEndPlayback:(SPSpotifySession *)aSession; {}

-(void)dealloc {
	[mainWindowController release];
	[loginWindowController release];
	self.session = nil;
	[super dealloc];
}

@end
