//
//  InboxViewController.m
//  Viva
//
//  Created by Daniel Kennett on 01/10/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import "InboxViewController.h"

@interface InboxViewController()

@property (nonatomic, readwrite, retain) SPPlaylist *playlist;

@end

@implementation InboxViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	if ((self = [super initWithObjectFromURL:aURL])) {
		
		[[SPSession sharedSession] addObserver:self
									forKeyPath:@"inboxPlaylist"
									   options:0
									   context:nil];
		
		self.playlist = [[SPSession sharedSession] inboxPlaylist];
		self.playlist.delegate = self;
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"inboxPlaylist"]) {
        self.playlist = [[SPSession sharedSession] inboxPlaylist];
		self.playlist.delegate = self;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@dynamic playlist;

-(void)dealloc {
	[[SPSession sharedSession] removeObserver:self forKeyPath:@"inboxPlaylist"];
	[super dealloc];
}

@end
