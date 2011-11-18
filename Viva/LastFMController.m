//
//  LastFMController.m
//  Viva
//
//  Created by Daniel Kennett on 14/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import "LastFMController.h"
#import "EMKeychain.h"
#import <Scribbler/Scribbler.h>

static NSString * const kLastFMUsernameUserDefaultsKey = @"LastFMUsername";
static NSString * const kLastFMConfiguredUserDefaultsKey = @"LastFMConfigured";
static NSString * const kLastFMAccountManagementURL = @"http://www.last.fm/settings/applications";

@interface LastFMController ()

-(void)connectWithStoredCredentials;
@property (readwrite, nonatomic) LastFMConnectionState connectionState;

@end

@implementation LastFMController

static LastFMController *sharedInstance;

+(LastFMController *)sharedInstance {
	if (sharedInstance == nil) {
		sharedInstance = [[LastFMController alloc] init]; 
	}
	
	return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
		// First, let's setup the web service object
		// You can obtain the API key and shared secret on your API info page
		//  - http://www.last.fm/api/account
		
		LFWebService *lastfm = [LFWebService sharedWebService];
		[lastfm setDelegate:self];
		[lastfm setAPIKey:@"fe6aa145ed0b397846e13d9082ac38d3"];
		[lastfm setSharedSecret:@"1a8dc69629e2fba3ba7543a5bde4b00f"];
		
		// We'll also set our client ID for scrobbling
		// You can obtain one of these by contacting Last.fm
		//  - http://www.last.fm/api/submissions#1.1
		// For now, we'll use the testing ID 'tst'
		[lastfm setClientID:@"tst"];
		[lastfm setClientVersion:@"1.0"];
		
		// We're also going to turn off autoscrobble, which
		// scrobbles the last playing track automatically
		// whenever a new track starts playing
		[lastfm setAutoScrobble:NO];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationDidBecomeActive:)
													 name:NSApplicationDidBecomeActiveNotification
												   object:nil];
		
		// In order to run, we need a valid session key
		// First, we'll check to see if we have one. If we do,
		// we'll set it, then test it. Otherwise, we'll wait for
		// someone to click the "Connect" button.
		[self connectWithStoredCredentials];
		
	}
    
    return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSApplicationDidBecomeActiveNotification
												  object:nil];
}

@synthesize connectionState;

-(NSString *)loggedInUser {
	return [[NSUserDefaults standardUserDefaults] valueForKey:kLastFMUsernameUserDefaultsKey];
}

-(void)applicationDidBecomeActive:(NSNotification *)aNotification {
	// If we have a pending authorization, this is our
	// cue to start trying to validate it, since the user likely
	// just switched back from the browser window
	if (self.connectionState == kLastFMWaitingForAuth)
		[[LFWebService sharedWebService] finishSessionAuthorization];
}

#pragma mark Authorization methods
-(void)connectWithStoredCredentials {
	// we have stored credentials, so we'll grab the user from the defaults,
	// then grab the session key from the keychain...
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kLastFMConfiguredUserDefaultsKey]) {
		
		NSString *theUser = [[NSUserDefaults standardUserDefaults] objectForKey:kLastFMUsernameUserDefaultsKey];
		NSString *keychainService = [NSString stringWithFormat:@"Last.fm (%@)", [[NSBundle mainBundle] bundleIdentifier]];
		EMGenericKeychainItem *keyItem = [EMGenericKeychainItem genericKeychainItemForService:keychainService withUsername:theUser];
		if (keyItem) {
			// we'll set both the user and session key in the web service
			LFWebService *lastfm = [LFWebService sharedWebService];
			[lastfm setSessionUser:theUser];
			[lastfm setSessionKey:[keyItem password]];
			
			// and then attempt to validate the credentials
			[lastfm validateSessionCredentials];
			
			// Adjust the UI
			self.connectionState = kLastFMWaitingForAuth;
			return;
		}
	}
	
	self.connectionState = kLastFMDisconnected;
}

-(IBAction)connectWithLastFM:(id)sender {
	// This means we're going to force establish a new Last.fm session
	[[LFWebService sharedWebService] establishNewSession];
	
	// Adjust the UI to show status
	self.connectionState = kLastFMWaitingForAuth;
}

-(IBAction)disconnectFromLastFM:(id)sender {
	// We need to get the username
	NSString *theUser = [[NSUserDefaults standardUserDefaults] objectForKey:kLastFMUsernameUserDefaultsKey];
	
	// We need to delete the user default information
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kLastFMConfiguredUserDefaultsKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastFMUsernameUserDefaultsKey];
	
	// And clear the Keychain info
	NSString *keychainService = [NSString stringWithFormat:@"Last.fm (%@)", [[NSBundle mainBundle] bundleIdentifier]];
	EMGenericKeychainItem *keyItem = [EMGenericKeychainItem genericKeychainItemForService:keychainService withUsername:theUser];
	if (keyItem)
		[keyItem setPassword:@""];
	
	// Finally, clear out the web service...
	LFWebService *lastfm = [LFWebService sharedWebService];
	[lastfm setSessionUser:nil];
	[lastfm setSessionKey:nil];
	
	// ... and update the UI
	self.connectionState = kLastFMDisconnected;
}

-(IBAction)openManagementPage:(id)sender {
	// Manage third-party application access on Last.fm
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kLastFMAccountManagementURL]];
}

#pragma mark Track methods

-(void)notifyPlaybackDidStart:(SPTrack *)track {
	
	if (self.connectionState != kLastFMConnected) return;
	
	LFTrack *lfTrack = [LFTrack trackWithTitle:track.name
										artist:track.artists.count > 0 ? ((SPArtist *)[track.artists objectAtIndex:0]).name : @""
									  duration:track.duration];
	[lfTrack play];
}

-(void)notifyPlaybackDidPause:(SPTrack *)track {
	
	if (self.connectionState != kLastFMConnected) return;
	
	LFTrack *lfTrack = [LFTrack trackWithTitle:track.name
										artist:track.artists.count > 0 ? ((SPArtist *)[track.artists objectAtIndex:0]).name : @""
									  duration:track.duration];
	[lfTrack pause];
}

-(void)notifyTrackPlaybackDidEnd:(SPTrack *)track atPosition:(NSTimeInterval)endPosition {
	
	if (self.connectionState != kLastFMConnected) return;
	
	LFTrack *lfTrack = [LFTrack trackWithTitle:track.name
										artist:track.artists.count > 0 ? ((SPArtist *)[track.artists objectAtIndex:0]).name : @""
									  duration:track.duration];
	lfTrack.playingTime = endPosition;
	[lfTrack stop]; // forces a scrobble
}

-(void)notifyLoveTrack:(SPTrack *)track {
	
	if (self.connectionState != kLastFMConnected) return;
	
	LFTrack *lfTrack = [LFTrack trackWithTitle:track.name
										artist:track.artists.count > 0 ? ((SPArtist *)[track.artists objectAtIndex:0]).name : @""
									  duration:track.duration];
	
	lfTrack.playingTime = track.duration;
	[lfTrack love];
	[lfTrack stop]; // forces a scrobble
}

#pragma mark Web service delegate methods

-(void)sessionNeedsAuthorizationViaURL:(NSURL *)theURL {
	// OK, so the first stage is done; we'll update the
	// UI to match the current status,
	// then open up the web browser to have the user allow our demo app
	// access
	self.connectionState = kLastFMWaitingForAuth;
	
	[[NSWorkspace sharedWorkspace] openURL:theURL];
}

-(void)sessionAuthorizationStillPending {
	// We tried to authorize the session, but the user
	// isn't done in the web browser yet. Wait 5 seconds,
	// then try again.
	[NSTimer scheduledTimerWithTimeInterval:5.0
									 target:self
								   selector:@selector(completeAuthorization:)
								   userInfo:nil
									repeats:NO];
}

-(void)completeAuthorization:(NSTimer *)timer {
	[[LFWebService sharedWebService] finishSessionAuthorization];
}

-(void)sessionAuthorizationFailed {
	// We failed. Epically.
	self.connectionState = kLastFMDisconnected;
}

-(void)sessionCreatedWithKey:(NSString *)theKey user:(NSString *)theUser {
	// The session key will be valid for future uses -- it never
	// expires unless explicitly revoked by the Last.fm user.
	// Therefore, we can store the user as a default, and then store
	// the key in the Keychain for future use.
	
	[[NSUserDefaults standardUserDefaults] setObject:theUser forKey:kLastFMUsernameUserDefaultsKey];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kLastFMConfiguredUserDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	NSString *keychainService = [NSString stringWithFormat:@"Last.fm (%@)", [[NSBundle mainBundle] bundleIdentifier]];
	EMGenericKeychainItem *keyItem = [EMGenericKeychainItem genericKeychainItemForService:keychainService withUsername:theUser];
	if (keyItem)
		[keyItem setPassword:theKey];
	else
		[EMGenericKeychainItem addGenericKeychainItemForService:keychainService withUsername:theUser password:theKey];
	
	// Hooray! we're up and running
	self.connectionState = kLastFMConnected;
}

-(void)sessionValidatedForUser:(NSString *)theUser {
	// Hooray! we're up and running
	self.connectionState = kLastFMConnected;
}

-(void)sessionInvalidForUser:(NSString *)theUser {
	// We failed. Epically.
	self.connectionState = kLastFMDisconnected;
}

-(void)sessionKeyRevoked:(NSString *)theKey forUser:(NSString *)theUser {
	// The key was revoked, so we disconnect from Last.fm permanently
	[self disconnectFromLastFM:self];
}

-(void)scrobblerHandshakeSucceeded {
}

-(void)scrobblerHandshakeFailed:(NSError *)theError willRetry:(BOOL)willRetry {
	//[self log:@"Handshake failed (retry=%d): %@", willRetry, [theError localizedDescription]];
}

-(void)scrobblerClient:(NSString *)theClientID bannedForVersion:(NSString *)theClientVersion {
	//[self log:@"Client banned"];
}
-(void)scrobblerRejectedSystemTime {
	//[self log:@"Time rejected"];
}

-(void)nowPlayingSucceededForTrack:(LFTrack *)theTrack {
	//NSLog(@"NP Success!");
}

-(void)scrobbleSucceededForTrack:(LFTrack *)theTrack {
	//NSLog(@"Scrobble Success!");
}

-(void)loveSucceededForTrack:(LFTrack *)theTrack {
}

-(void)banSucceededForTrack:(LFTrack *)theTrack {
}

-(void)nowPlayingFailedForTrack:(LFTrack *)theTrack error:(NSError *)theError willRetry:(BOOL)willRetry {
	//[self log:@"Now playing failed (retry=%d): %@ (%@) - %@", willRetry, [theTrack title], [theTrack artist], [theError localizedDescription]];
	//NSLog(@"%@", theError);
}

-(void)scrobbleFailedForTrack:(LFTrack *)theTrack error:(NSError *)theError willRetry:(BOOL)willRetry {
	//[self log:@"Scrobble failed (retry=%d): %@ (%@) - %@", willRetry, [theTrack title], [theTrack artist], [theError localizedDescription]];
	//NSLog(@"%@", theError);
}

-(void)loveFailedForTrack:(LFTrack *)theTrack error:(NSError *)theError willRetry:(BOOL)willRetry {
	//[self log:@"Love failed (retry=%d): %@ (%@) - %@", willRetry, [theTrack title], [theTrack artist], [theError localizedDescription]];
}

-(void)banFailedForTrack:(LFTrack *)theTrack error:(NSError *)theError willRetry:(BOOL)willRetry {
	//[self log:@"Ban failed (retry=%d): %@ (%@) - %@", willRetry, [theTrack title], [theTrack artist], [theError localizedDescription]];
}

@end
