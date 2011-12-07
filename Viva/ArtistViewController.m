//
//  ArtistViewController.m
//  Viva
//
//  Created by Daniel Kennett on 4/24/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "ArtistViewController.h"
#import "VivaTrackInContainerReference.h"
#import "MainWindowController.h"
#import "VivaInternalURLManager.h"
#import "VivaAlbumIKImageViewProxy.h"

@interface ArtistViewController ()

@property (nonatomic, readwrite, strong) SPArtistBrowse *artistBrowse;
@property (nonatomic, readwrite, strong) NSArray *albums;
@property (nonatomic, readwrite, strong) NSArray *relatedAlbums;
@property (nonatomic, retain, readwrite) NSMutableDictionary *albumProxyCache;
@property (nonatomic, readwrite) BOOL canAnimateImageBrowser;

-(void)rebuildAlbums;
-(void)rebuildTrackContainers;

@end

@implementation ArtistViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	if ((self = [super initWithObjectFromURL:aURL])) {
		
		[self addObserver:self
			   forKeyPath:@"artistBrowse.tracks"
				  options:0
				  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"artistBrowse.albums"
				  options:0
				  context:nil];
		
		self.albumProxyCache = [[NSMutableDictionary alloc] init];
		
		SPSession *appSession = [[NSApp delegate] session];
		self.artistBrowse = [[SPArtistBrowse alloc] initWithArtist:[SPArtist artistWithArtistURL:aURL]
																 inSession:appSession
															   type:SP_ARTISTBROWSE_NO_TRACKS];
	}
	return self;
}

-(void)awakeFromNib {
	[self.imageBrowser setValue:[NSColor colorWithCalibratedRed:0.907 green:0.903 blue:0.887 alpha:1.000] forKey:IKImageBrowserBackgroundColorKey];
	[self.imageBrowser setContentResizingMask:NSViewHeightSizable];
	[self.imageBrowser reloadData];
	if (self.canAnimateImageBrowser)
		[self.imageBrowser setAnimates:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"artistBrowse.tracks"]) {
        
		NSArray *containerTracks = [self.trackContainers valueForKey:@"track"];
		if (![containerTracks isEqualToArray:self.artistBrowse.tracks]) {
			[self rebuildTrackContainers];
		}
		
	} else if ([keyPath isEqualToString:@"artistBrowse.albums"]) {
		
		[self rebuildAlbums];
		[self.imageBrowser setAnimates:YES];
		self.canAnimateImageBrowser = YES;
		
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)rebuildAlbums {
	
	NSArray *newAlbums = self.artistBrowse.albums;
	NSMutableSet *albumSet = [NSMutableSet setWithCapacity:newAlbums.count];
	NSMutableSet *appearsInSet = [NSMutableSet setWithCapacity:newAlbums.count];
	
	for (SPAlbum *anAlbum in newAlbums) {
		if (![anAlbum.spotifyURL.absoluteString isEqualToString:@"spotify:album:0000000000000000000000"]) {
			if (anAlbum.artist == self.artistBrowse.artist)
				[albumSet addObject:anAlbum];
			else
				[appearsInSet addObject:anAlbum];
		}
	}
	
	self.albums = [[albumSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(SPAlbum *obj1, SPAlbum *obj2) {
		
		if (obj1.year == obj2.year)
			return [obj1.name caseInsensitiveCompare:obj2.name];
		
		return obj2.year - obj1.year;
	}];
	
	self.relatedAlbums = [[appearsInSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(SPAlbum *obj1, SPAlbum *obj2) {
		
		if (obj1.year == obj2.year)
			return [obj1.name caseInsensitiveCompare:obj2.name];
		
		return obj2.year - obj1.year;
	}];
	
	[self.imageBrowser reloadData];
}

-(void)rebuildTrackContainers {
	
	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[self.artistBrowse.tracks count]];
	
	for (SPTrack *aTrack in self.artistBrowse.tracks) {
		[newContainers addObject:[[VivaTrackInContainerReference alloc] initWithTrack:aTrack
																		   inContainer:self.artistBrowse]];
	}
	self.trackContainers = [NSMutableArray arrayWithArray:newContainers];
}


@synthesize imageBrowser;
@synthesize artistBrowse;
@synthesize albums;
@synthesize relatedAlbums;
@synthesize albumProxyCache;
@synthesize canAnimateImageBrowser;

#pragma mark -

-(void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index {
	
	SPAlbum *album = nil;
	
	if (index < self.albums.count)
		album = [self.albums objectAtIndex:index];
	else
		album = [self.relatedAlbums objectAtIndex:index - self.albums.count];

	((VivaURLNavigationController *)[(MainWindowController *)self.view.window.windowController navigationController]).thePresent = album.spotifyURL;
}

-(NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser {
	return self.albums.count + self.relatedAlbums.count;
}

-(NSUInteger)numberOfGroupsInImageBrowser:(IKImageBrowserView *)aBrowser {
	return self.relatedAlbums.count > 0 ? 1 : 0;
}

-(NSDictionary *)imageBrowser:(IKImageBrowserView *)aBrowser groupAtIndex:(NSUInteger)index {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"Also Appears On", IKImageBrowserGroupTitleKey,
			[NSNumber numberWithInt:IKGroupDisclosureStyle], IKImageBrowserGroupStyleKey,
			[NSValue valueWithRange:NSMakeRange(self.albums.count, self.relatedAlbums.count)], IKImageBrowserGroupRangeKey,
			nil];
}

-(id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index {
	
	VivaAlbumIKImageViewProxy *proxy = nil;
	SPAlbum *album = nil;
	
	if (index < self.albums.count)
		album = [self.albums objectAtIndex:index];
	else
		album = [self.relatedAlbums objectAtIndex:index - self.albums.count];
	
	[album.cover beginLoading];
	
	proxy = [self.albumProxyCache valueForKey:album.spotifyURL.absoluteString];
	if (proxy == nil) {
		proxy = [[VivaAlbumIKImageViewProxy alloc] initWithAlbum:album imageView:self.imageBrowser];
		proxy.mode = kSubtitleModeYear;
		[self.albumProxyCache setValue:proxy forKey:album.spotifyURL.absoluteString];
	}
	
	proxy.imageView = self.imageBrowser;
	return proxy;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"artistBrowse.tracks"];
	[self removeObserver:self forKeyPath:@"artistBrowse.albums"];
}

@end
