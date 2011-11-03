//
//  StarredViewController.m
//  Viva
//
//  Created by Daniel Kennett on 7/26/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "StarredViewController.h"

@interface StarredViewController()

@property (nonatomic, readwrite, strong) SPPlaylist *playlist;

@end

@implementation StarredViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	if ((self = [super initWithObjectFromURL:aURL])) {
		
		[[SPSession sharedSession] addObserver:self
									forKeyPath:@"starredPlaylist"
									   options:0
									   context:nil];
		
		self.playlist = [[SPSession sharedSession] starredPlaylist];
		self.playlist.delegate = self.playlistProxy;
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"starredPlaylist"]) {
        self.playlist = [[SPSession sharedSession] starredPlaylist];
		self.playlist.delegate = self.playlistProxy;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@dynamic playlist;

-(void)dealloc {
	[[SPSession sharedSession] removeObserver:self forKeyPath:@"starredPlaylist"];
}

@end
