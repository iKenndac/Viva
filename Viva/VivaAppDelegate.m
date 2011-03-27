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

@synthesize loginSheet;
@synthesize window;
@synthesize session;
@synthesize usernameField;
@synthesize passwordField;

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
	
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[PlaylistViewController class] forURLScheme:@"spotify:user"];
	
    [self setSession:[SPSpotifySession sessionWithApplicationKey:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"libspotify_appkey"
                                                                                                                                ofType:@"key"]]
                                                       userAgent:@"CocoaLibSpotify"
                                                           error:nil]];
    [[self session] setDelegate:self];
    
    [NSApp beginSheet:[self loginSheet]
       modalForWindow:[self window]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}


- (IBAction)login:(id)sender {

    [NSApp endSheet:[self loginSheet]];
    [[self loginSheet] orderOut:self];

    [[self session] attemptLoginWithUserName:[[self usernameField] stringValue]
                                    password:[[self passwordField] stringValue]];
}

- (IBAction)cancelLogin:(id)sender {
    
    [NSApp endSheet:[self loginSheet]];
    [[self loginSheet] orderOut:self];
    
    [NSApp terminate:sender];
}

#pragma mark -

-(void)sessionDidLoginSuccessfully:(SPSpotifySession *)aSession; {}

-(void)session:(SPSpotifySession *)aSession didFailToLoginWithError:(NSError *)error; {
    
    [NSApp presentError:error
         modalForWindow:[self window]
               delegate:self
     didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:)
            contextInfo:nil];
}

-(void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo {
    [NSApp beginSheet:[self loginSheet]
       modalForWindow:[self window]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}
     
-(void)sessionDidLogOut:(SPSpotifySession *)aSession; {}


-(void)session:(SPSpotifySession *)aSession didEncounterNetworkError:(NSError *)error; {}
-(void)session:(SPSpotifySession *)aSession didLogMessage:(NSString *)aMessage; {}
-(void)sessionDidChangeMetadata:(SPSpotifySession *)aSession; {}

-(void)session:(SPSpotifySession *)aSession recievedMessageForUser:(NSString *)aMessage; {}
-(void)sessionDidLosePlayToken:(SPSpotifySession *)aSession; {}
-(void)sessionDidEndPlayback:(SPSpotifySession *)aSession; {}

-(void)dealloc {
	self.session = nil;
	[super dealloc];
}

@end
