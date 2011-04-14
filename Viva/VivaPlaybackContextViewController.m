//
//  VivaPlaybackContextViewController.m
//  Viva
//
//  Created by Daniel Kennett on 4/9/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaPlaybackContextViewController.h"
#import "Constants.h"

@interface VivaPlaybackContextViewController()

@property (nonatomic, readwrite, copy) NSURL *spotifyURL;

@end

@implementation VivaPlaybackContextViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle mainBundle]])) {
		self.spotifyURL = aURL;
	}
	return self;
}

@synthesize spotifyURL;
@synthesize trackContainersForPlayback;

-(void)playTrackContainerInThisContext:(id <VivaTrackContainer>)trackContainer {
	[[NSNotificationCenter defaultCenter] postNotificationName:kTrackShouldBePlayedNotification
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:trackContainer forKey:kPlaybackInitialTrackContainerKey]];
}

- (void)dealloc
{
	self.spotifyURL = nil;
    [super dealloc];
}

@end
