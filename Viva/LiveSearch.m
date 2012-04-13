//
//  LiveSearch.m
//  Viva
//
//  Created by Daniel Kennett on 6/9/11.
//  For license information, see LICENSE.markdown
//

#import "LiveSearch.h"
#import "Constants.h"

@interface LiveSearch ()

@property (nonatomic, readwrite, copy) NSArray *topTracks;
@property (nonatomic, readwrite, copy) NSArray *topArtists;
@property (nonatomic, readwrite, copy) NSArray *topAlbums;
@property (nonatomic, readwrite, strong) id topHit;

@end

@implementation LiveSearch

-(id)initWithInitialSearch:(SPSearch *)aSearch {
    self = [super init];
    if (self) {
        // Initialization code here.
		
		[self addObserver:self
			   forKeyPath:@"latestSearch.loaded"
				  options:0
				  context:nil];
		
		self.latestSearch = aSearch;
    }
    
    return self;
}

-(void)clear {
	self.topHit = nil;
	self.topTracks = nil;
	self.topArtists = nil;
	self.topAlbums = nil;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"latestSearch.loaded"]) {
		
		if (!self.latestSearch.isLoaded)
			return;
		
		self.topAlbums = [self.latestSearch.albums subarrayWithRange:NSMakeRange(0, self.latestSearch.albums.count > kLiveSearchMaximumResultsPerCategoryCount ? kLiveSearchMaximumResultsPerCategoryCount : self.latestSearch.albums.count)];
		self.topArtists = [self.latestSearch.artists subarrayWithRange:NSMakeRange(0, self.latestSearch.artists.count > kLiveSearchMaximumResultsPerCategoryCount ? kLiveSearchMaximumResultsPerCategoryCount : self.latestSearch.artists.count)];
		self.topTracks = [self.latestSearch.tracks subarrayWithRange:NSMakeRange(0, self.latestSearch.tracks.count > kLiveSearchMaximumResultsPerCategoryCount ? kLiveSearchMaximumResultsPerCategoryCount : self.latestSearch.tracks.count)];
		
		id secondChoice = nil;
		
		for (SPArtist *artist in self.topArtists) {
			NSRange rangeOfQuery = [artist.name rangeOfString:self.latestSearch.searchQuery options:NSCaseInsensitiveSearch];
			if (rangeOfQuery.location == 0) {
				self.topHit = artist;
				return;
			} else if (rangeOfQuery.location != NSNotFound) {
				secondChoice = artist;
			}
		}
		
		for (SPAlbum *album in self.topAlbums) {
			NSRange rangeOfQuery = [album.name rangeOfString:self.latestSearch.searchQuery options:NSCaseInsensitiveSearch];
			if (rangeOfQuery.location == 0) {
				self.topHit = album;
				return;
			} else if (rangeOfQuery.location != NSNotFound && secondChoice == nil) {
				secondChoice = album;
			}
		}
		
		for (SPTrack *track in self.topTracks) {
			NSRange rangeOfQuery = [track.name rangeOfString:self.latestSearch.searchQuery options:NSCaseInsensitiveSearch];
			if (rangeOfQuery.location == 0) {
				self.topHit = track;
				return;
			} else if (rangeOfQuery.location != NSNotFound && secondChoice == nil) {
				secondChoice = track;
			}
		}
		
		self.topHit = secondChoice;
		
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@synthesize latestSearch;
@synthesize topTracks;
@synthesize topArtists;
@synthesize topAlbums;
@synthesize topHit;

-(void)dealloc {
	
	
	[self removeObserver:self
			  forKeyPath:@"latestSearch.loaded"];
	
	[self clear];
}

@end
