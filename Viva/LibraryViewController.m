//
//  LibraryViewController.m
//  Viva
//
//  Created by Daniel Kennett on 04/12/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import "LibraryViewController.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaAlbumIKImageViewProxy.h"
#import "VivaArtistIKImageViewProxy.h"
#import "VivaURLNavigationController.h"
#import "MainWindowController.h"

static NSString * const kLibraryViewControllerRebuildAlbumsKVOContext = @"kLibraryViewControllerRebuildAlbumsKVOContext";

@interface LibraryViewController ()

@property (nonatomic, copy, readwrite) NSArray *albums;
@property (nonatomic, copy, readwrite) NSArray *artists;
@property (nonatomic, readwrite) BOOL showArtists;
@property (nonatomic, retain, readwrite) NSMutableDictionary *albumProxyCache;
@property (nonatomic, retain, readwrite) NSMutableDictionary *artistProxyCache;

-(void)rebuildAlbumsAndArtists;
-(NSArray *)playlistsInFolder:(SPPlaylistFolder *)aFolder;
-(NSArray *)tracksFromPlaylistItems:(NSArray *)items;

@end

@implementation LibraryViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	
	self = [super initWithNibName:@"LibraryViewController" bundle:nil];
	
	if (self) {
		
		self.albumProxyCache = [[NSMutableDictionary alloc] init];
		self.artistProxyCache = [[NSMutableDictionary alloc] init];
		
		[self loadView];
		[self.imageBrowser setContentResizingMask:NSViewHeightSizable];
		
		[[SPSession sharedSession] addObserver:self
									forKeyPath:@"userPlaylists"
									   options:0
									   context:(__bridge void *)kLibraryViewControllerRebuildAlbumsKVOContext];
		
		[[SPSession sharedSession] addObserver:self
									forKeyPath:@"starredPlaylist"
									   options:NSKeyValueObservingOptionInitial
									   context:(__bridge void *)kLibraryViewControllerRebuildAlbumsKVOContext];
	}
	
	return self;
}

-(void)dealloc {
	[[SPSession sharedSession] removeObserver:self forKeyPath:@"userPlaylists"];
	[[SPSession sharedSession] removeObserver:self forKeyPath:@"starredPlaylist"];
}

@synthesize albumProxyCache;
@synthesize artistProxyCache;
@synthesize imageBrowser;
@synthesize albums;
@synthesize artists;
@synthesize showArtists;

-(void)viewControllerDidActivateWithContext:(id)context {}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void *)kLibraryViewControllerRebuildAlbumsKVOContext) {
		[self rebuildAlbumsAndArtists];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(IBAction)switchViews:(id)sender {
	NSSegmentedControl *segmentedControl = (NSSegmentedControl *)sender;
	self.showArtists = (segmentedControl.selectedSegment == 1);
	[self.imageBrowser reloadData];
}

-(void)rebuildAlbumsAndArtists {
	
	BOOL hasScheduledRebuild = NO;
	
	SPPlaylist *starred = [[SPSession sharedSession] starredPlaylist];
	SPPlaylist *inbox = [[SPSession sharedSession] inboxPlaylist];
	
	if (!starred.isLoaded || !inbox.isLoaded) {
		[self performSelector:_cmd withObject:nil afterDelay:0.2];
		hasScheduledRebuild = YES;
	}
	
	NSMutableArray *playlistPool = [NSMutableArray arrayWithObjects:starred, inbox, nil];
	
	if (![SPSession sharedSession].userPlaylists.isLoaded) {
		[self performSelector:_cmd withObject:nil afterDelay:0.2];
		hasScheduledRebuild = YES;
	}
	
	for (id playlistOrFolder in [SPSession sharedSession].userPlaylists.playlists) {
		if ([playlistOrFolder isKindOfClass:[SPPlaylist class]]) {
			[playlistPool addObject:(SPPlaylist *)playlistOrFolder];
		} else {
			[playlistPool addObjectsFromArray:[self playlistsInFolder:(SPPlaylistFolder *)playlistOrFolder]];
		}
	}
	
	if (!hasScheduledRebuild) {
		for (SPPlaylist *aPlaylist in playlistPool) {
			if (!aPlaylist.isLoaded) {
				[self performSelector:_cmd withObject:nil afterDelay:0.2];
				hasScheduledRebuild = YES;
				break;
			}
		}
	}
	
	NSMutableArray *trackPool = [NSMutableArray arrayWithArray:[self tracksFromPlaylistItems:[playlistPool valueForKeyPath:@"@unionOfArrays.items"]]];
	NSArray *newAlbums = [trackPool valueForKey:@"album"];
	NSArray *newArtists = [trackPool valueForKeyPath:@"@unionOfArrays.artists"];
	
	NSMutableSet *artistSet = [NSMutableSet setWithCapacity:newArtists.count];
	NSMutableSet *albumSet = [NSMutableSet setWithCapacity:newAlbums.count];
	
	for (SPAlbum *anAlbum in newAlbums) {
		if (![anAlbum.spotifyURL.absoluteString isEqualToString:@"spotify:album:0000000000000000000000"])
			[albumSet addObject:anAlbum];
	}
	
	for (SPArtist *anArtist in newArtists) {
		if (![anArtist.spotifyURL.absoluteString isEqualToString:@"spotify:artist:0000000000000000000000"])
			[artistSet addObject:anArtist];
	}
	
	self.albums = [[albumSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(SPAlbum *obj1, SPAlbum *obj2) {
		return [obj1.name caseInsensitiveCompare:obj2.name];
	}];
	
	self.artists = [[artistSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(SPArtist *obj1, SPArtist *obj2) {
		return [obj1.name caseInsensitiveCompare:obj2.name];
	}];

	[self.imageBrowser reloadData];
	
	if (!hasScheduledRebuild)
		[self.imageBrowser setAnimates:YES];
}

-(NSArray *)playlistsInFolder:(SPPlaylistFolder *)aFolder {
	
	NSMutableArray *playlists = [NSMutableArray arrayWithCapacity:[[aFolder playlists] count]];
	
	for (id playlistOrFolder in aFolder.playlists) {
		if ([playlistOrFolder isKindOfClass:[SPPlaylist class]]) {
			[playlists addObject:playlistOrFolder];
		} else {
			[playlists addObjectsFromArray:[self playlistsInFolder:playlistOrFolder]];
		}
	}
	return [NSArray arrayWithArray:playlists];
}

-(NSArray *)tracksFromPlaylistItems:(NSArray *)items {
	
	NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:items.count];
	
	for (SPPlaylistItem *anItem in items) {
		if (anItem.itemClass == [SPTrack class]) {
			[tracks addObject:anItem.item];
		}
	}
	
	return [NSArray arrayWithArray:tracks];
}

#pragma mark -

-(void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index {
	
	NSURL *url = nil;
	
	if (self.showArtists) {
		SPArtist *artist = [self.artists objectAtIndex:index];
		url = artist.spotifyURL;
	} else {
		SPAlbum *album = [self.albums objectAtIndex:index];
		url = album.spotifyURL;
	}
	
	((VivaURLNavigationController *)[(MainWindowController *)self.view.window.windowController navigationController]).thePresent = url;
}

-(NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser {
	return self.showArtists ? self.artists.count : self.albums.count;
}

-(id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index {
	
	id proxy = nil;
	
	if (!self.showArtists) {
		
		SPAlbum *album = [self.albums objectAtIndex:index];
		[album.cover beginLoading];
		
		proxy = [self.albumProxyCache valueForKey:album.spotifyURL.absoluteString];
		if (proxy == nil) {
			proxy = [[VivaAlbumIKImageViewProxy alloc] initWithAlbum:album imageView:self.imageBrowser];
			[self.albumProxyCache setValue:proxy forKey:album.spotifyURL.absoluteString];
		}
		
	} else {
		
		SPArtist *artist = [self.artists objectAtIndex:index];
	
		proxy = [self.artistProxyCache valueForKey:artist.spotifyURL.absoluteString];
		if (proxy == nil) {
			proxy = [[VivaArtistIKImageViewProxy alloc] initWithArtist:artist imageView:self.imageBrowser];
			[self.artistProxyCache setValue:proxy forKey:artist.spotifyURL.absoluteString];
		}
		
	}
	
	[proxy setImageView:(id)self.imageBrowser];
	return proxy;
}

@end
