//
//  SearchResultsViewController.m
//  Viva
//
//  Created by Daniel Kennett on 4/22/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "SearchResultsViewController.h"
#import "VivaTrackInContainerReference.h"

@interface SearchResultsViewController ()

@property (nonatomic, readwrite, strong) SPSearch *search;

-(void)rebuildTrackContainers;

@end

@implementation SearchResultsViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	if ((self = [super initWithObjectFromURL:aURL])) {
		
		[self addObserver:self
			   forKeyPath:@"search.tracks"
				  options:0
				  context:nil];

		self.search = [[SPSearch alloc] initWithURL:aURL
												  inSession:[[NSApp delegate] session]];
	}
	return self;
}

@synthesize search;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"search.tracks"]) {
        
		NSArray *containerTracks = [self.trackContainers valueForKey:@"track"];
		if (![containerTracks isEqualToArray:self.search.tracks]) {
			[self rebuildTrackContainers];
		}
		
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)rebuildTrackContainers {
	
	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[self.search.tracks count]];
	
	for (SPTrack *aTrack in self.search.tracks) {
		[newContainers addObject:[[VivaTrackInContainerReference alloc] initWithTrack:aTrack
																		   inContainer:self.search]];
	}
	self.trackContainers = [NSMutableArray arrayWithArray:newContainers];
}


- (void)dealloc {
	[self removeObserver:self forKeyPath:@"search.tracks"];
}

@end
