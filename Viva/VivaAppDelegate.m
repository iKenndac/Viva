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

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
	
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[PlaylistViewController class] forURLScheme:@"spotify:user"];
	
    [self setSession:[SPSpotifySession sessionWithApplicationKey:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"libspotify_appkey"
                                                                                                                                ofType:@"key"]]
                                                       userAgent:@"CocoaLibSpotify"
                                                           error:nil]];
    [[self session] setDelegate:self];
    
	mainWindowController = [[MainWindowController alloc] init];
	loginWindowController = [[LoginWindowController alloc] init];
	playbackManager = [[VivaPlaybackManager alloc] init];
	[loginWindowController showWindow:nil];

}

#pragma mark -

-(NSInteger)session:(SPSpotifySession *)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat {
	return [self.playbackManager session:aSession
				shouldDeliverAudioFrames:audioFrames
								 ofCount:frameCount
								  format:audioFormat];
}

-(void)sessionDidEndPlayback:(SPSpotifySession *)aSession {
	[self.playbackManager sessionDidEndPlayback:aSession];
}

-(void)sessionDidLosePlayToken:(SPSpotifySession *)aSession {
	[self.playbackManager sessionDidLosePlayToken:aSession];
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
