//
//  VivaAppDelegate.m
//  Viva
//
//  Created by Daniel Kennett on 3/7/11.
//  For license information, see LICENSE.markdown
//

#import "VivaAppDelegate.h"
#import "PlaylistViewController.h"
#import "VivaInternalURLManager.h"
#import "Constants.h"
#import "NSObject+Spotify.h"
#import "SearchResultsViewController.h"
#import "AlbumViewController.h"
#import "ArtistViewController.h"
#import "StarredViewController.h"
#import "InboxViewController.h"
#import "LocalFilesController.h"
#import "LibraryViewController.h"
#import "LocalFilesViewController.h"

extern int *_NSGetArgc(void);
extern char ***_NSGetArgv(void);

static NSString * const kSPPerformActionOnNotificationKVOContext = @"kSPPerformActionOnNotificationKVOContext";

@interface VivaAppDelegate()

@property (strong, readwrite) VivaPlaybackManager *playbackManager; 
@property (strong, readwrite) SPMediaKeyTap *mediaKeyHandler;
@property (strong, readwrite) NSURL *urlToHandleOnLogin;

@end

@implementation VivaAppDelegate

@synthesize window;
@synthesize playbackManager;
@synthesize dockMenu;
@synthesize mediaKeyHandler;
@synthesize urlToHandleOnLogin;

-(SPSession *)session {
	return [SPSession sharedSession];
}

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
	
	[GrowlApplicationBridge setGrowlDelegate:self];
	
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
													   andSelector:@selector(handleURLEvent:withReplyEvent:)
													 forEventClass:kInternetEventClass
														andEventID:kAEGetURL];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
															 [SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers], kMediaKeyUsingBundleIdentifiersDefaultsKey,
															 [NSNumber numberWithBool:YES], kScrobblePlaybackToLastFMUserDefaultsKey,
															 [NSNumber numberWithBool:YES], kStarEqualsLastFMLoveUserDefaultsKey,
															 nil]];
	
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[PlaylistViewController class] forURLScheme:@"spotify:user"];
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[SearchResultsViewController class] forURLScheme:@"spotify:search"];
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[AlbumViewController class] forURLScheme:@"spotify:album"];
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[ArtistViewController class] forURLScheme:@"spotify:artist"];
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[StarredViewController class] forURLScheme:@"spotify:internal:starred"];
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[InboxViewController class] forURLScheme:@"spotify:internal:inbox"];
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[LibraryViewController class] forURLScheme:@"spotify:internal:library"];
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[LocalFilesViewController class] forURLScheme:@"spotify:internal:local-files"];
	
    // Look for -mu arguments in argv
    NSString *muValue = nil;
    
    char **argv = *_NSGetArgv();
    for (NSUInteger argIndex = 0; argIndex < *_NSGetArgc(); argIndex++) {
        if (strcmp("-mu", argv[argIndex]) == 0 && argIndex < (*_NSGetArgc() - 1))
            muValue = [NSString stringWithUTF8String:argv[argIndex + 1]];
    }
    
	//#error Please put your appkey.c file in the root of the Viva project and remove this error
    #import "../appkey.c"
    
    NSString *userAgent = kVivaLibSpotifyUserAgentName;
    if (muValue)
        userAgent = [NSString stringWithFormat:@"%@-%@", userAgent, muValue];
    
	NSError *error = nil;
	[SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:g_appkey length:g_appkey_size]
											   userAgent:userAgent
										   loadingPolicy:SPAsyncLoadingImmediate
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
	[[SPSession sharedSession] setPreferredBitrate:SP_BITRATE_320k];
    
	mainWindowController = [[MainWindowController alloc] init];
	loginWindowController = [[LoginWindowController alloc] init];
	self.playbackManager = [[VivaPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];
    self.playbackManager.dataSource = mainWindowController;
	
	if ([SPMediaKeyTap usesGlobalMediaKeyTap]) {
		self.mediaKeyHandler = [[SPMediaKeyTap alloc] initWithDelegate:self];
		[self.mediaKeyHandler startWatchingMediaKeys];
	} else {
		NSLog(@"Media key monitoring disabled because CGEventTap + gdb = pain");
	}
	
	[LocalFilesController sharedInstance];
	
	[NSApp setDockMenu:self.dockMenu];
	[loginWindowController showWindow:nil];

}

-(BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
	if (mainWindowController != nil) {
		[mainWindowController showWindow:nil];
	}
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	if ([SPSession sharedSession].connectionState == SP_CONNECTION_STATE_LOGGED_OUT ||
		[SPSession sharedSession].connectionState == SP_CONNECTION_STATE_UNDEFINED) 
		return NSTerminateNow;
	
	[[SPSession sharedSession] beginLogout:nil];
	return NSTerminateLater;
}


#pragma mark -

-(void)logOut {
	
	[mainWindowController close];
	
	[[SPSession sharedSession] beginLogout:^{
		[[SPSession sharedSession] forgetStoredCredentials];
		[loginWindowController reset];
		[loginWindowController showWindow:nil];
	}];
}

#pragma mark - GrowlApplicationBridgeDelegate Methods

-(NSDictionary *)registrationDictionaryForGrowl {
    return [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSArray arrayWithObject:kGrowlNotificationNameNewTrack], [NSArray arrayWithObject:kGrowlNotificationNameNewTrack], nil]
                                       forKeys:[NSArray arrayWithObjects:GROWL_NOTIFICATIONS_ALL, GROWL_NOTIFICATIONS_DEFAULT, nil ]];
}

-(NSString *)applicationNameForGrowl {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
}

- (void)growlNotificationWasClicked:(id)clickContext {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:clickContext]];
}

-(void)growlIsReady {
    NSLog(@"Growl is ready");
}


#pragma mark -

-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event {

	int keyCode = (([event data1] & 0xFFFF0000) >> 16);
	int keyFlags = ([event data1] & 0x0000FFFF);
	int keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA;
	//int keyRepeat = (keyFlags & 0x1);
	int keyRepeat = 0; // Seeking doesn't work properly yet!
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
	if (self.playbackManager.currentTrack == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTrackShouldBePlayedNotification
                                                            object:nil
                                                          userInfo:nil];
        
    } else {
        self.playbackManager.playing = !self.playbackManager.playing;
    }
}

-(IBAction)performVolumeUpAction:(id)sender {
	self.playbackManager.audioController.volume = MIN(1.0, self.playbackManager.audioController.volume + kVolumeStepSize);
}

-(IBAction)performVolumeDownAction:(id)sender {
	self.playbackManager.audioController.volume = MAX(0.0, self.playbackManager.audioController.volume - kVolumeStepSize);
}

#pragma mark -

- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent {
    
	NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	NSURL *url = [NSURL URLWithString:urlString];
	[self handleURL:url];
}

-(void)handleURL:(NSURL *)url {
	
	if (!mainWindowController.window.isVisible) {
		self.urlToHandleOnLogin = url;
		return;
	}
	
	if (![[VivaInternalURLManager sharedInstance] canHandleURL:url]) {
		
		if ([url spotifyLinkType] == SP_LINKTYPE_TRACK) {
			
			[[SPSession sharedSession] trackForURL:url callback:^(SPTrack *track) {
				
				
				[SPAsyncLoading waitUntilLoaded:track timeout:5.0 then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
					
					if (loadedItems.count > 0)
						[SPAsyncLoading waitUntilLoaded:track.album timeout:5.0 then:^(NSArray *loadedAlbums, NSArray *notLoadedAlbums) {
							
							if (loadedAlbums.count > 0)
								[mainWindowController navigateToURL:track.album.spotifyURL withContext:track];
							
						}];
				}];
			}];
		}
	}
	mainWindowController.navigationController.thePresent = url;
}

#pragma mark -

-(void)sessionDidLoginSuccessfully:(SPSession *)aSession; {

	[mainWindowController showWindow:nil];
	[[loginWindowController window] orderOut:nil]; 
	loginWindowController.isLoggingIn = NO;
	
	if (self.urlToHandleOnLogin != nil) {
		[self handleURL:self.urlToHandleOnLogin];
		self.urlToHandleOnLogin = nil;
	}
	
}

-(void)session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error; {
    
    [NSApp presentError:error
         modalForWindow:[loginWindowController window]
               delegate:nil
     didPresentSelector:nil
            contextInfo:nil];
	
	loginWindowController.isLoggingIn = NO;
}
    
-(void)sessionDidLogOut:(SPSession *)aSession; {
    if ([NSRunLoop currentRunLoop].currentMode == NSModalPanelRunLoopMode)
        [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
    // Only quit when logging out if we're in NSModalPanelRunLoopMode, which is what
    // returning NSTerminateLater in applicationWillTerminate causes.
}

-(void)session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error; {}
-(void)session:(SPSession *)aSession didLogMessage:(NSString *)aMessage; {}
-(void)sessionDidChangeMetadata:(SPSession *)aSession; {}

-(void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {}

-(void)dealloc {
	[self.mediaKeyHandler stopWatchingMediaKeys];
	
}

@end
