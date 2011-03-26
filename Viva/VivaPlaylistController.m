//
//  VivaPlaylistController.m
//  Viva
//
//  Created by Daniel Kennett on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VivaPlaylistController.h"

@interface VivaPlaylistController ()

@property (readwrite, assign, nonatomic) __weak SPSpotifyPlaylist *playlist;

@end

@implementation VivaPlaylistController

- (id)initWithPlaylist:(__weak SPSpotifyPlaylist *)aPlaylist
{
    self = [super init];
    if (self) {
		self.playlist = aPlaylist;
	}
    
    return self;
}

@synthesize playlist;

- (void)dealloc
{
	playlist = nil;
    [super dealloc];
}

@end
