//
//  ArtistViewController.m
//  Viva
//
//  Created by Daniel Kennett on 4/24/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "ArtistViewController.h"
#import "VivaTrackInContainerReference.h"

@interface ArtistViewController ()

@property (nonatomic, readwrite, retain) SPArtistBrowse *artistBrowse;

-(void)rebuildTrackContainers;

@end

@implementation ArtistViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	if ((self = [super initWithObjectFromURL:aURL])) {
		
		[self addObserver:self
			   forKeyPath:@"artistBrowse.tracks"
				  options:0
				  context:nil];
		
		SPSession *appSession = [[NSApp delegate] session];
		self.artistBrowse = [[[SPArtistBrowse alloc] initWithArtist:[SPArtist artistWithArtistURL:aURL]
																 inSession:appSession]
							autorelease];
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"artistBrowse.tracks"]) {
        
		NSArray *containerTracks = [self.trackContainers valueForKey:@"track"];
		if (![containerTracks isEqualToArray:self.artistBrowse.tracks]) {
			NSLog(@"Containers not in sync with tracks - rebuilding.");
			[self rebuildTrackContainers];
		}
		
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)rebuildTrackContainers {
	
	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[self.artistBrowse.tracks count]];
	
	for (SPTrack *aTrack in self.artistBrowse.tracks) {
		[newContainers addObject:[[[VivaTrackInContainerReference alloc] initWithTrack:aTrack
																		   inContainer:self.artistBrowse] autorelease]];
	}
	self.trackContainers = [NSMutableArray arrayWithArray:newContainers];
}


@synthesize artistBrowse;

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"artistBrowse.tracks"];
	self.artistBrowse = nil;
    [super dealloc];
}
@end
