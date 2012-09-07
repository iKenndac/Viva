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

@property (nonatomic, copy, readwrite) NSArray *albumProxies;
@property (nonatomic, copy, readwrite) NSArray *artistProxies;
@property (nonatomic, readwrite) BOOL showArtists;
@property (nonatomic, readwrite) BOOL canAnimateImageBrowser;

-(void)rebuildAlbumsAndArtists;
-(NSArray *)tracksFromPlaylistItems:(NSArray *)items;

@end

@implementation LibraryViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	
	self = [super initWithNibName:@"LibraryViewController" bundle:nil];
	
	if (self) {
		
		// Wait  for login to settle down.
		[self performSelector:@selector(initialSetup) withObject:nil afterDelay:2.0];
		
	}
	
	return self;
}

-(void)initialSetup {

	[[SPSession sharedSession] addObserver:self
								forKeyPath:@"userPlaylists"
								   options:0
								   context:(__bridge void *)kLibraryViewControllerRebuildAlbumsKVOContext];

	[[SPSession sharedSession] addObserver:self
								forKeyPath:@"starredPlaylist"
								   options:NSKeyValueObservingOptionInitial
								   context:(__bridge void *)kLibraryViewControllerRebuildAlbumsKVOContext];

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

@synthesize imageBrowser;
@synthesize albumProxies;
@synthesize artistProxies;
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
					
					NSSet *newAlbums = [NSSet setWithArray:[loadedTracks valueForKey:@"album"]];
					NSSet *newArtists = [NSSet setWithArray:[loadedTracks valueForKeyPath:@"@unionOfArrays.artists"]];
					
					NSMutableSet *artistSet = [NSMutableSet setWithCapacity:newArtists.count];
					NSMutableSet *albumSet = [NSMutableSet setWithCapacity:newAlbums.count];
					
					for (SPAlbum *anAlbum in newAlbums) {
						if (anAlbum != (id)[NSNull null] && ![anAlbum.spotifyURL.absoluteString isEqualToString:@"spotify:album:0000000000000000000000"])
							[albumSet addObject:[[VivaAlbumIKImageViewProxy alloc] initWithAlbum:anAlbum imageView:nil]];
					}
					
					for (SPArtist *anArtist in newArtists) {
						if (anArtist != (id)[NSNull null] && ![anArtist.spotifyURL.absoluteString isEqualToString:@"spotify:artist:0000000000000000000000"])
							[artistSet addObject:[[VivaArtistIKImageViewProxy alloc] initWithArtist:anArtist imageView:nil]];
					}
					
					self.albumProxies = [[albumSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(VivaAlbumIKImageViewProxy *obj1, VivaAlbumIKImageViewProxy *obj2) {
						return [obj1.album.name caseInsensitiveCompare:obj2.album.name];
					}];
					
					self.artistProxies = [[artistSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(VivaArtistIKImageViewProxy *obj1, VivaArtistIKImageViewProxy *obj2) {
						return [obj1.artist.name caseInsensitiveCompare:obj2.artist.name];
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
		SPArtist *artist = [[self.artistProxies objectAtIndex:index] artist];
		url = artist.spotifyURL;
	} else {
		SPAlbum *album = (id)[[self.albumProxies objectAtIndex:index] album];
		url = album.spotifyURL;
	}
	
	((VivaURLNavigationController *)[(MainWindowController *)self.view.window.windowController navigationController]).thePresent = url;
}

-(NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser {
	return self.showArtists ? self.artistProxies.count : self.albumProxies.count;
}

-(id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index {
	
	id proxy = nil;
	
	if (!self.showArtists)
		proxy = [self.albumProxies objectAtIndex:index];
	else
		proxy = [self.artistProxies objectAtIndex:index];
	
	[proxy setImageView:(id)self.imageBrowser];
	return proxy;
}

@end
