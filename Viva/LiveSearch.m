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
			   forKeyPath:@"latestSearch.albums"
				  options:0
				  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"latestSearch.artists"
				  options:0
				  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"latestSearch.tracks"
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
	
	if ([keyPath isEqualToString:@"latestSearch.albums"]) {
		if (self.latestSearch.albums.count == 0)
			return;
		self.topAlbums = [self.latestSearch.albums subarrayWithRange:NSMakeRange(0, self.latestSearch.albums.count > kLiveSearchMaximumResultsPerCategoryCount ? kLiveSearchMaximumResultsPerCategoryCount : self.latestSearch.albums.count)];
	}
	
	if ([keyPath isEqualToString:@"latestSearch.artists"]) {
		if (self.latestSearch.artists.count == 0)
			return;
		self.topArtists = [self.latestSearch.artists subarrayWithRange:NSMakeRange(0, self.latestSearch.artists.count > kLiveSearchMaximumResultsPerCategoryCount ? kLiveSearchMaximumResultsPerCategoryCount : self.latestSearch.artists.count)];
	}
	
	if ([keyPath isEqualToString:@"latestSearch.tracks"]) {
		if (self.latestSearch.tracks.count == 0)
			return;
		self.topTracks = [self.latestSearch.tracks subarrayWithRange:NSMakeRange(0, self.latestSearch.tracks.count > kLiveSearchMaximumResultsPerCategoryCount ? kLiveSearchMaximumResultsPerCategoryCount : self.latestSearch.tracks.count)];
	}
}

@synthesize latestSearch;
@synthesize topTracks;
@synthesize topArtists;
@synthesize topAlbums;

-(void)dealloc {
	
	[self removeObserver:self
			  forKeyPath:@"latestSearch.albums"];
	
	[self removeObserver:self
			  forKeyPath:@"latestSearch.artists"];
	
	[self removeObserver:self
			  forKeyPath:@"latestSearch.tracks"];
	
	[self clear];
	self.latestSearch = nil;
	[super dealloc];
}

@end
