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
	return [self initWithObjectFromURL:aURL nibName:NSStringFromClass([self class])];
}

-(id)initWithObjectFromURL:(NSURL *)aURL nibName:(NSString *)nibName {
	if ((self = [super initWithNibName:nibName bundle:[NSBundle mainBundle]])) {
		self.spotifyURL = aURL;
	}
	return self;
}

@synthesize spotifyURL;
@synthesize trackContainersForPlayback;
@synthesize playingTrackContainer;
@synthesize playingTrackContainerIsCurrentlyPlaying;

-(void)setPlayingTrackContainer:(id <VivaTrackContainer>)aTrackContainer isPlaying:(BOOL)playing {
	self.playingTrackContainer = aTrackContainer;
	playingTrackContainerIsCurrentlyPlaying = playing;
}

-(void)playTrackContainerInThisContext:(id <VivaTrackContainer>)trackContainer {
	[[NSNotificationCenter defaultCenter] postNotificationName:kTrackShouldBePlayedNotification
														object:self
													  userInfo:[NSDictionary dictionaryWithObject:trackContainer forKey:kPlaybackInitialTrackContainerKey]];
}


@end
