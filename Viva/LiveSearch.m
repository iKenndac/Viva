//
//  LiveSearch.m
//  Viva
//
//  Created by Daniel Kennett on 6/9/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "LiveSearch.h"
#import "Constants.h"

@interface LiveSearch ()

@property (nonatomic, readwrite, copy) NSArray *topTracks;
@property (nonatomic, readwrite, copy) NSArray *topArtists;
@property (nonatomic, readwrite, copy) NSArray *topAlbums;

@end

@implementation LiveSearch

-(id)initWithInitialSearch:(SPSearch *)aSearch {
    self = [super init];
    if (self) {
        // Initialization code here.
		
		[self addObserver:self
			   forKeyPath:@"latestSearch.searchInProgress"
				  options:0
				  context:nil];
		
		self.latestSearch = aSearch;
    }
    
    return self;
}

-(void)clear {
	self.topTracks = nil;
	self.topArtists = nil;
	self.topAlbums = nil;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"latestSearch.searchInProgress"]) {
		
		if (self.latestSearch.searchInProgress)
			return;
		
		self.topAlbums = [self.latestSearch.albums subarrayWithRange:NSMakeRange(0, self.latestSearch.albums.count > kLiveSearchMaximumResultsPerCategoryCount ? kLiveSearchMaximumResultsPerCategoryCount : self.latestSearch.albums.count)];
		self.topArtists = [self.latestSearch.artists subarrayWithRange:NSMakeRange(0, self.latestSearch.artists.count > kLiveSearchMaximumResultsPerCategoryCount ? kLiveSearchMaximumResultsPerCategoryCount : self.latestSearch.artists.count)];
		self.topTracks = [self.latestSearch.tracks subarrayWithRange:NSMakeRange(0, self.latestSearch.tracks.count > kLiveSearchMaximumResultsPerCategoryCount ? kLiveSearchMaximumResultsPerCategoryCount : self.latestSearch.tracks.count)];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@synthesize latestSearch;
@synthesize topTracks;
@synthesize topArtists;
@synthesize topAlbums;

-(void)dealloc {
	
	[self removeObserver:self
			  forKeyPath:@"latestSearch.searchInProgress"];
	
	[self clear];
	self.latestSearch = nil;
	[super dealloc];
}

@end
