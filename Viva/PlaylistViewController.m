//
//  PlaylistViewController.m
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlaylistViewController.h"

@implementation SPSpotifyPlaylist (SPViewControllerCreationExtensions)

-(NSViewController *)createViewController {
	return [[[PlaylistViewController alloc] initWithPlaylist:self] autorelease];
}

@end

@interface PlaylistViewController ()

@property (nonatomic, readwrite, retain) __weak SPSpotifyPlaylist *playlist;

@end

@implementation PlaylistViewController

-(id)initWithPlaylist:(SPSpotifyPlaylist *)aPlaylist {
	if ((self = [super initWithNibName:@"PlaylistViewController" bundle:nil])) {
		self.playlist = aPlaylist;
	}
	return self;
}

@synthesize playlist;

- (void)dealloc
{
	self.playlist = nil;
    [super dealloc];
}

@end
