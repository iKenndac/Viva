//
//  PlaylistViewController.m
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "PlaylistViewController.h"
#import "SPTableHeaderCell.h"
#import "SPTableCorner.h"
#import "VivaAppDelegate.h"
#import "VivaSortDescriptorExtensions.h"
#import "VivaTrackInPlaylistReference.h"

@interface PlaylistViewController ()

@property (nonatomic, readwrite, retain) SPSpotifyPlaylist *playlist;
@property (nonatomic, readwrite, retain) NSArray *trackContainers;

-(void)rebuildTrackContainers;

@end

@implementation PlaylistViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	if ((self = [super initWithObjectFromURL:aURL])) {
		
		[self addObserver:self
			   forKeyPath:@"playlist.tracks"
				  options:0
				  context:nil];
		
		self.playlist = [[(VivaAppDelegate *)[NSApp delegate] session] playlistForURL:aURL];
	}
	return self;
}

-(void)awakeFromNib {

	sortAscending = YES;
	
	// No IB support for custom headers. Yay!
	
	for (NSTableColumn *column in [self.trackTable tableColumns]) {
		SPTableHeaderCell *newCell = [[[SPTableHeaderCell alloc] init] autorelease];
		[newCell setObjectValue:[[column headerCell] objectValue]];
		[column setHeaderCell:newCell];
	}
	
	[self.trackTable setCornerView:[[[SPTableCorner alloc] init] autorelease]];
	
	[self.trackTable setTarget:self];
	[self.trackTable setDoubleAction:@selector(playTrack:)];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"playlist.tracks"]) {
        [self rebuildTrackContainers];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)rebuildTrackContainers {
	
	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[self.playlist.tracks count]];
	
	for (SPSpotifyTrack *aTrack in self.playlist.tracks) {
		[newContainers addObject:[[[VivaTrackInPlaylistReference alloc] initWithTrack:aTrack
																		   inPlaylist:self.playlist] autorelease]];
	}
	self.trackContainers = [NSArray arrayWithArray:newContainers];
}

-(IBAction)playTrack:(id)sender {
	if ([self.trackTable clickedRow] > -1) {
		id <VivaTrackContainer> container = [[self.trackContainerArrayController arrangedObjects] objectAtIndex:[self.trackTable clickedRow]];
		[self playTrackContainerInThisContext:container];
	}
}

+(NSSet *)keyPathsForValuesAffectingTracksForPlayback {
	return [NSSet setWithObject:@"trackContainerArrayController.arrangedObjects"];
}

-(NSArray *)trackContainersForPlayback {
	return [NSArray arrayWithArray:[self.trackContainerArrayController arrangedObjects]];
}

@synthesize trackContainers;
@synthesize trackContainerArrayController;
@synthesize trackTable;
@synthesize playlist;

#pragma mark -

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	// Either reverse the sort or change the sorting column
	
	for (NSTableColumn *col in [tableView tableColumns]) {
		if ([(SPTableHeaderCell *)[col headerCell] sortPriority] == 0) {
			if (col == tableColumn) {
				sortAscending = !sortAscending;
			}
		}
	}
	
	for (NSTableColumn *col in [tableView tableColumns]) {
		if (tableView == self.trackTable) {
			if (col == tableColumn) {
				if ([[tableColumn identifier] isEqualToString:@"title"]) {
					[self.trackContainerArrayController setSortDescriptors:[NSSortDescriptor trackSortDescriptorsForTitleAscending:sortAscending]];
				} else if ([[tableColumn identifier] isEqualToString:@"album"]) {
					[self.trackContainerArrayController setSortDescriptors:[NSSortDescriptor trackSortDescriptorsForAlbumAscending:sortAscending]];
				}
				[(SPTableHeaderCell *)[col headerCell] setSortAscending:[[[self.trackContainerArrayController sortDescriptors] objectAtIndex:0] ascending] priority:0];
			} else {
				[(SPTableHeaderCell *)[col headerCell] setSortAscending:YES priority:1];
			}
			
			[[self.trackTable headerView] setNeedsDisplay:YES];
		}
	}
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"playlist.tracks"];
	self.trackContainers = nil;
	self.playlist = nil;
    [super dealloc];
}

@end
