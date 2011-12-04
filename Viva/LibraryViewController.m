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
#import "VivaURLNavigationController.h"
#import "MainWindowController.h"

static NSString * const kLibraryViewControllerRebuildAlbumsKVOContext = @"kLibraryViewControllerRebuildAlbumsKVOContext";

@interface LibraryViewController ()

@property (nonatomic, copy, readwrite) NSArray *albums;
@property (nonatomic, copy, readwrite) NSMutableDictionary *albumProxyCache;

-(void)rebuildAlbums;
-(NSArray *)playlistsInFolder:(SPPlaylistFolder *)aFolder;
-(NSArray *)tracksFromPlaylistItems:(NSArray *)items;

@end

@implementation LibraryViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	
	self = [super initWithNibName:@"LibraryViewController" bundle:nil];
	
	if (self) {
		
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
@synthesize imageBrowser;
@synthesize albums;

-(void)viewControllerDidActivateWithContext:(id)context {}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == (__bridge void *)kLibraryViewControllerRebuildAlbumsKVOContext) {
		NSLog(@"Rebuild");
        [self rebuildAlbums];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)rebuildAlbums {
	
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
				break;
			}
		}
	}
	
	NSMutableArray *trackPool = [NSMutableArray arrayWithArray:[self tracksFromPlaylistItems:[playlistPool valueForKeyPath:@"@unionOfArrays.items"]]];
	NSMutableArray *newAlbums = [trackPool valueForKey:@"album"];
	
	NSMutableSet *albumSet = [NSMutableSet setWithCapacity:newAlbums.count];
	
	for (SPAlbum *anAlbum in newAlbums) {
		if (![anAlbum.spotifyURL.absoluteString isEqualToString:@"spotify:album:0000000000000000000000"])
			[albumSet addObject:anAlbum];
	}
	
	self.albums = [[albumSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(SPAlbum *obj1, SPAlbum *obj2) {
		return [obj1.name caseInsensitiveCompare:obj2.name];
	}];
	
	[self.imageBrowser reloadData];
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
	
	SPAlbum *album = [self.albums objectAtIndex:index];
	NSURL *albumURL = album.spotifyURL;
	
	((VivaURLNavigationController *)[(MainWindowController *)self.view.window.windowController navigationController]).thePresent = albumURL;
}

-(NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser {
	return self.albums.count;
}

-(id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index {
	SPAlbum *album = [self.albums objectAtIndex:index];
	[album.cover beginLoading];
	
	VivaAlbumIKImageViewProxy *proxy = [self.albumProxyCache valueForKey:album.spotifyURL.absoluteString];
	if (proxy == nil) {
		proxy = [[VivaAlbumIKImageViewProxy alloc] initWithAlbum:album imageView:self.imageBrowser];
		[self.albumProxyCache setValue:proxy forKey:album.spotifyURL.absoluteString];
	}
	
	proxy.imageView = self.imageBrowser;
	return proxy;
}

@end
