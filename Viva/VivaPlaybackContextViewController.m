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
@synthesize tracksForPlayback;

-(void)playTrackInThisContext:(SPSpotifyTrack *)track {
	[[NSNotificationCenter defaultCenter] postNotificationName:kTrackShouldBePlayedNotification
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:track forKey:kPlaybackInitialTrackKey]];
}

- (void)dealloc
{
	self.spotifyURL = nil;
    [super dealloc];
}

@end
