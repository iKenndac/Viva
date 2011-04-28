//
//  AlbumViewController.m
//  Viva
//
//  Created by Daniel Kennett on 4/24/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "AlbumViewController.h"
#import "VivaTrackInContainerReference.h"

@interface AlbumViewController ()

@property (nonatomic, readwrite, retain) SPAlbumBrowse *albumBrowse;

-(void)rebuildTrackContainers;

@end

@implementation AlbumViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	if ((self = [super initWithObjectFromURL:aURL])) {
		
		[self addObserver:self
			   forKeyPath:@"albumBrowse.tracks"
				  options:0
				  context:nil];
		
		SPSession *appSession = [[NSApp delegate] session];
		self.albumBrowse = [[[SPAlbumBrowse alloc] initWithAlbum:[SPAlbum albumWithAlbumURL:aURL
																								inSession:appSession]
															  inSession:appSession]
							autorelease];
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"albumBrowse.tracks"]) {
        
		NSArray *containerTracks = [self.trackContainers valueForKey:@"track"];
		if (![containerTracks isEqualToArray:self.albumBrowse.tracks]) {
			NSLog(@"Containers not in sync with tracks - rebuilding.");
			[self rebuildTrackContainers];
		}
		
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)rebuildTrackContainers {
	
	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[self.albumBrowse.tracks count]];
	
	for (SPTrack *aTrack in self.albumBrowse.tracks) {
		[newContainers addObject:[[[VivaTrackInContainerReference alloc] initWithTrack:aTrack
																		   inContainer:self.albumBrowse] autorelease]];
	}
	self.trackContainers = [NSMutableArray arrayWithArray:newContainers];
}


@synthesize albumBrowse;

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"albumBrowse.tracks"];
	self.albumBrowse = nil;
    [super dealloc];
}

@end
