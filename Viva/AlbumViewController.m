//
//  AlbumViewController.m
//  Viva
//
//  Created by Daniel Kennett on 4/24/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "AlbumViewController.h"
#import "VivaTrackInContainerReference.h"
#import "VivaAlbumTableRowView.h"

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
		
		SPSession *appSession = [[NSApp delegate] session];
		self.albumBrowse = [[SPAlbumBrowse alloc] initWithAlbum:[SPAlbum albumWithAlbumURL:aURL
																								inSession:appSession]
															  inSession:appSession];
	}
	return self;
}

-(void)awakeFromNib {
	[super awakeFromNib];
	self.backgroundColorView.backgroundColor = [NSColor colorWithCalibratedRed:0.907 green:0.903 blue:0.887 alpha:1.000];	
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
	return [[VivaAlbumTableRowView alloc] init];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"albumBrowse.tracks"]) {
        
		NSArray *containerTracks = [self.trackContainers valueForKey:@"track"];
		if (![containerTracks isEqualToArray:self.albumBrowse.tracks]) {
			[self rebuildTrackContainers];
		}
		
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

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	
	if ([tableColumn.identifier isEqualToString:@"playIndicator"]) {
		
		id <VivaTrackContainer> container = [[self.trackContainerArrayController arrangedObjects] objectAtIndex:row];
		NSImageView *imageView = [cellView.subviews objectAtIndex:0];
		
		if (container == self.playingTrackContainer) {
			if (self.playingTrackContainerIsCurrentlyPlaying) {
				imageView.image = [NSImage imageNamed:@"playing-indicator"];
			} else {
				imageView.image = [NSImage imageNamed:@"paused-indicator"];
			}
		} else {
			imageView.image = nil;
		}
		
	}
	
	return cellView;
}

@synthesize backgroundColorView;
@synthesize albumBrowse;

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"albumBrowse.tracks"];
}

@end
