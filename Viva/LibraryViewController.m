//
//  LibraryViewController.m
//  Viva
//
//  Created by Daniel Kennett on 04/12/2011.
//  For license information, see LICENSE.markdown
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
@property (nonatomic, readwrite) BOOL canAnimateImageBrowser;

-(void)rebuildAlbumsAndArtists;
-(NSArray *)tracksFromPlaylistItems:(NSArray *)items;

@end

@implementation LibraryViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	
	self = [super initWithNibName:@"LibraryViewController" bundle:nil];
	
	if (self) {
		
		self.albumProxyCache = [[NSMutableDictionary alloc] init];
		self.artistProxyCache = [[NSMutableDictionary alloc] init];
		
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

-(void)awakeFromNib {
	self.headerView.backgroundColor = [NSColor colorWithCalibratedRed:0.907 green:0.903 blue:0.887 alpha:1.000];
	[self.imageBrowser setValue:[NSColor colorWithCalibratedRed:0.907 green:0.903 blue:0.887 alpha:1.000] forKey:IKImageBrowserBackgroundColorKey];
	[self.imageBrowser setContentResizingMask:NSViewHeightSizable];
	[self.imageBrowser reloadData];
	if (self.canAnimateImageBrowser)
		[self.imageBrowser setAnimates:YES];
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
@synthesize headerView;
@synthesize canAnimateImageBrowser;

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
	
	[SPAsyncLoading waitUntilLoaded:[SPSession sharedSession] timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedSession, NSArray *notloadedSession) {
		
		[SPAsyncLoading waitUntilLoaded:[SPSession sharedSession].userPlaylists timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *userPl, NSArray *notLoadedPl) {
			
			SPPlaylist *starred = [[SPSession sharedSession] starredPlaylist];
			SPPlaylist *inbox = [[SPSession sharedSession] inboxPlaylist];
			NSMutableArray *playlistPool = [NSMutableArray arrayWithObjects:starred, inbox, nil];
			[playlistPool addObjectsFromArray:[SPSession sharedSession].userPlaylists.flattenedPlaylists];
			
			[SPAsyncLoading waitUntilLoaded:playlistPool timeout:10.0 then:^(NSArray *loadedPlaylists, NSArray *notLoadedPlaylists) {
				
				NSMutableArray *trackPool = [NSMutableArray arrayWithArray:[self tracksFromPlaylistItems:[loadedPlaylists valueForKeyPath:@"@unionOfArrays.items"]]];
				
				[SPAsyncLoading waitUntilLoaded:trackPool timeout:10.0 then:^(NSArray *loadedTracks, NSArray *notLoadedTracks) {
					
					NSArray *newAlbums = [loadedTracks valueForKey:@"album"];
					NSArray *newArtists = [loadedTracks valueForKeyPath:@"@unionOfArrays.artists"];
					
					NSMutableSet *artistSet = [NSMutableSet setWithCapacity:newArtists.count];
					NSMutableSet *albumSet = [NSMutableSet setWithCapacity:newAlbums.count];
					
					for (SPAlbum *anAlbum in newAlbums) {
						if (anAlbum != (id)[NSNull null] && ![anAlbum.spotifyURL.absoluteString isEqualToString:@"spotify:album:0000000000000000000000"])
							[albumSet addObject:anAlbum];
					}
					
					for (SPArtist *anArtist in newArtists) {
						if (anArtist != (id)[NSNull null] && ![anArtist.spotifyURL.absoluteString isEqualToString:@"spotify:artist:0000000000000000000000"])
							[artistSet addObject:anArtist];
					}
					
					self.albums = [[albumSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(SPAlbum *obj1, SPAlbum *obj2) {
						return [obj1.name caseInsensitiveCompare:obj2.name];
					}];
					
					self.artists = [[artistSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(SPArtist *obj1, SPArtist *obj2) {
						return [obj1.name caseInsensitiveCompare:obj2.name];
					}];
					
					self.canAnimateImageBrowser = YES;
					[self.imageBrowser setAnimates:YES];
					[self.imageBrowser reloadData];
				}];
			}];
		}];
	}];
	
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
		[album.cover startLoading];
		
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
