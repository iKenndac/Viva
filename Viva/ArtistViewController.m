//
//  ArtistViewController.m
//  Viva
//
//  Created by Daniel Kennett on 4/24/11.
//  For license information, see LICENSE.markdown
//

#import "ArtistViewController.h"
#import "VivaTrackInContainerReference.h"
#import "MainWindowController.h"
#import "VivaInternalURLManager.h"
#import "VivaAlbumIKImageViewProxy.h"

@interface ArtistViewController ()

@property (nonatomic, readwrite, strong) SPArtistBrowse *artistBrowse;
@property (nonatomic, readwrite, strong) NSArray *albumProxies;
@property (nonatomic, readwrite, strong) NSArray *relatedAlbumProxies;
@property (nonatomic, readwrite) BOOL canAnimateImageBrowser;

-(void)rebuildAlbums;

@end

@implementation ArtistViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	if ((self = [super initWithNibName:@"ArtistViewController" bundle:nil])) {
		
		[self addObserver:self
			   forKeyPath:@"artistBrowse.albums"
				  options:0
				  context:nil];

		[self addObserver:self
			   forKeyPath:@"artistBrowse.artist.spotifyURL"
				  options:0
				  context:nil];
		
		SPSession *appSession = [[NSApp delegate] session];
		
		[SPArtistBrowse browseArtistAtURL:aURL
								inSession:appSession
									 type:SP_ARTISTBROWSE_NO_TRACKS
								 callback:^(SPArtistBrowse *newArtistBrowse) {
									 self.artistBrowse = newArtistBrowse;
								 }];
	}
	return self;
}

-(void)viewControllerDidActivateWithContext:(id)context {}

-(void)awakeFromNib {
	self.headerView.backgroundColor = [NSColor colorWithCalibratedRed:0.907 green:0.903 blue:0.887 alpha:1.000];
	[self.imageBrowser setValue:[NSColor colorWithCalibratedRed:0.907 green:0.903 blue:0.887 alpha:1.000] forKey:IKImageBrowserBackgroundColorKey];
	[self.imageBrowser setContentResizingMask:NSViewHeightSizable];
	[self.imageBrowser reloadData];
	if (self.canAnimateImageBrowser)
		[self.imageBrowser setAnimates:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"artistBrowse.albums"]) {
		
		[self rebuildAlbums];
		[self.imageBrowser setAnimates:YES];
		self.canAnimateImageBrowser = YES;
	} else if ([keyPath isEqualToString:@"artistBrowse.artist.spotifyURL"]) {
		self.artistImageView.itemURL = self.artistBrowse.artist.spotifyURL;
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if (menuItem.action == @selector(copySpotifyURI:)) {
		return self.imageBrowser.selectionIndexes.count == 1;
	}
	return NO;
}

-(IBAction)copySpotifyURI:(id)sender {
	
	SPAlbum *album = nil;
	
	if (self.imageBrowser.selectionIndexes.count == 1) {
		
		NSUInteger index = self.imageBrowser.selectionIndexes.firstIndex;
		
		if (index < self.albumProxies.count)
			album = (id)[[self.albumProxies objectAtIndex:index] album];
		else
			album = (id)[[self.albumProxies objectAtIndex:index - self.albumProxies.count] album];
	}
	
	if (album == nil) {
		NSBeep();
		return;
	}
	
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	
	[pasteboard declareTypes:[NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil] owner:nil];
	[pasteboard setString:album.spotifyURL.absoluteString forType:NSStringPboardType];
	[album.spotifyURL writeToPasteboard:pasteboard];
	
}

-(void)rebuildAlbums {
	
	NSArray *newAlbums = self.artistBrowse.albums;
	NSMutableSet *albumProxySet = [NSMutableSet setWithCapacity:newAlbums.count];
	NSMutableSet *appearsInSet = [NSMutableSet setWithCapacity:newAlbums.count];
	
	for (SPAlbum *anAlbum in newAlbums) {
		if (![anAlbum.spotifyURL.absoluteString isEqualToString:@"spotify:album:0000000000000000000000"]) {
			if (anAlbum.artist == self.artistBrowse.artist)
				[albumProxySet addObject:[[VivaAlbumIKImageViewProxy alloc] initWithAlbum:anAlbum imageView:nil]];
			else
				[appearsInSet addObject:[[VivaAlbumIKImageViewProxy alloc] initWithAlbum:anAlbum imageView:nil]];
		}
	}
	
	self.albumProxies = [[albumProxySet allObjects] sortedArrayUsingComparator:^NSComparisonResult(VivaAlbumIKImageViewProxy *obj1, VivaAlbumIKImageViewProxy *obj2) {
		
		if (obj1.album.year == obj2.album.year)
			return [obj1.album.name caseInsensitiveCompare:obj2.album.name];
		
		return obj2.album.year - obj1.album.year;
	}];
	
	self.relatedAlbumProxies = [[appearsInSet allObjects] sortedArrayUsingComparator:^NSComparisonResult(VivaAlbumIKImageViewProxy *obj1, VivaAlbumIKImageViewProxy *obj2) {

		if (obj1.album.year == obj2.album.year)
			return [obj1.album.name caseInsensitiveCompare:obj2.album.name];

		return obj2.album.year - obj1.album.year;
	}];
	
	[self.imageBrowser reloadData];
}


@synthesize imageBrowser;
@synthesize artistBrowse;
@synthesize albumProxies;
@synthesize relatedAlbumProxies;
@synthesize headerView;
@synthesize artistImageView;
@synthesize canAnimateImageBrowser;

#pragma mark -

-(void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index {
	
	SPAlbum *album = nil;
	
	if (index < self.albumProxies.count)
		album = (id)[[self.albumProxies objectAtIndex:index] album];
	else
		album = (id)[[self.relatedAlbumProxies objectAtIndex:index - self.albumProxies.count] album];

	((VivaURLNavigationController *)[(MainWindowController *)self.view.window.windowController navigationController]).thePresent = album.spotifyURL;
}

-(NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser {
	return self.albumProxies.count + self.relatedAlbumProxies.count;
}

-(NSUInteger)numberOfGroupsInImageBrowser:(IKImageBrowserView *)aBrowser {
	return self.relatedAlbumProxies.count > 0 ? 1 : 0;
}

-(NSDictionary *)imageBrowser:(IKImageBrowserView *)aBrowser groupAtIndex:(NSUInteger)index {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"Also Appears On", IKImageBrowserGroupTitleKey,
			[NSNumber numberWithInt:IKGroupDisclosureStyle], IKImageBrowserGroupStyleKey,
			[NSValue valueWithRange:NSMakeRange(self.albumProxies.count, self.relatedAlbumProxies.count)], IKImageBrowserGroupRangeKey,
			nil];
}

-(id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index {
	
	VivaAlbumIKImageViewProxy *proxy = nil;
	
	if (index < self.albumProxies.count)
		proxy = [self.albumProxies objectAtIndex:index];
	else
		proxy = [self.relatedAlbumProxies objectAtIndex:index - self.albumProxies.count];

	proxy.mode = kSubtitleModeYear;
	proxy.imageView = self.imageBrowser;
	return proxy;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"artistBrowse.albums"];
	[self removeObserver:self forKeyPath:@"artistBrowse.artist.spotifyURL"];
}

@end
