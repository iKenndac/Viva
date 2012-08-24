//
//  AlbumViewController.m
//  Viva
//
//  Created by Daniel Kennett on 4/24/11.
//  For license information, see LICENSE.markdown
//

#import "AlbumViewController.h"
#import "VivaTrackInContainerReference.h"
#import "VivaAlbumTableRowView.h"
#import "VivaLinkTextField.h"

@interface AlbumViewController ()

@property (nonatomic, readwrite, strong) SPAlbumBrowse *albumBrowse;

-(void)rebuildTrackContainers;

@end

@implementation AlbumViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	if ((self = [super initWithObjectFromURL:aURL])) {
		
		[self addObserver:self
			   forKeyPath:@"albumBrowse.tracks"
				  options:0
				  context:nil];

		[self addObserver:self
			   forKeyPath:@"albumBrowse.album.spotifyURL"
				  options:0
				  context:nil];

		[self addObserver:self
			   forKeyPath:@"albumBrowse.album.artist.name"
				  options:0
				  context:nil];
		
		SPSession *appSession = [[NSApp delegate] session];
		
		[SPAlbumBrowse browseAlbumAtURL:aURL
							  inSession:appSession
							   callback:^(SPAlbumBrowse *newAlbumBrowse) {
								   self.albumBrowse = newAlbumBrowse;
							   }];
	}
	return self;
}

-(void)awakeFromNib {
	[super awakeFromNib];
	self.leftColumnColorView.backgroundColor = [NSColor colorWithCalibratedRed:0.907 green:0.903 blue:0.887 alpha:1.000];
	self.backgroundColorView.backgroundColor = [NSColor whiteColor];
	self.albumCoverView.layer.backgroundColor = [NSColor whiteColor].CGColor;

	self.artistView.activeColor = [NSColor darkGrayColor];
	self.artistView.textFont = [NSFont fontWithName:@"Helvetica" size:12.0];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"albumBrowse.tracks"]) {
        
		NSArray *containerTracks = [self.trackContainers valueForKey:@"track"];
		if (![containerTracks isEqualToArray:self.albumBrowse.tracks]) {
			[self rebuildTrackContainers];
		}

	} else if ([keyPath isEqualToString:@"albumBrowse.album.spotifyURL"]) {
		self.albumCoverView.itemURL = self.albumBrowse.album.spotifyURL;

	} else if ([keyPath isEqualToString:@"albumBrowse.album.artist.name"]) {
		NSURL *url = self.albumBrowse.album.artist.spotifyURL;
		NSString * name = self.albumBrowse.album.artist.name;
		if (url != nil && name != nil)
			self.artistView.items = @[@{kVivaLinkViewItemKey : url, kVivaLinkViewItemTitleKey : name}];
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)rebuildTrackContainers {
	
	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[self.albumBrowse.tracks count]];
	
	for (SPTrack *aTrack in self.albumBrowse.tracks) {
		[newContainers addObject:[[VivaTrackInContainerReference alloc] initWithTrack:aTrack
																		   inContainer:self.albumBrowse]];
	}
	self.trackContainers = [NSMutableArray arrayWithArray:newContainers];
}

+(NSSet *)keyPathsForValuesAffectingCondensedCopyrights {
	return [NSSet setWithObjects:@"albumBrowse.copyrights", nil];
}

-(NSString *)condensedCopyrights {
	return [self.albumBrowse.copyrights componentsJoinedByString:@", "];
}


@synthesize backgroundColorView;
@synthesize leftColumnColorView;
@synthesize albumCoverView;
@synthesize artistView;
@synthesize albumBrowse;

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"albumBrowse.album.spotifyURL"];
	[self removeObserver:self forKeyPath:@"albumBrowse.tracks"];
	[self removeObserver:self forKeyPath:@"albumBrowse.album.artist.name"];
}

@end
