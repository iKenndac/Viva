//
//  VivaSortableTrackListController.m
//  Viva
//
//  Created by Daniel Kennett on 4/22/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaSortableTrackListController.h"
#import "SPTableHeaderCell.h"
#import "SPTableCorner.h"
#import "VivaSortDescriptorExtensions.h"
#import "Constants.h"

@implementation VivaSortableTrackListController

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
	
	[self addObserver:self 
		   forKeyPath:@"playingTrackContainerIsCurrentlyPlaying"
			  options:0
			  context:nil];
	
	[self addObserver:self
		   forKeyPath:@"playingTrackContainer"
			  options:0
			  context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"playingTrackContainer"] || [keyPath isEqualToString:@"playingTrackContainerIsCurrentlyPlaying"]) {
		[self.trackTable reloadData];
		if (self.playingTrackContainer != nil)
			[self.trackTable scrollRowToVisible:[self.trackContainerArrayController.arrangedObjects indexOfObject:self.playingTrackContainer]];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@synthesize trackContainers;
@synthesize trackContainerArrayController;
@synthesize trackTable;

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

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	// Either reverse the sort or change the sorting column
	
	if ([[tableColumn identifier] isEqualToString:@"playIndicator"])
		return;
	
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
					[self.trackContainerArrayController setSortDescriptors:[NSSortDescriptor trackContainerSortDescriptorsForTitleAscending:sortAscending]];
				} else if ([[tableColumn identifier] isEqualToString:@"album"]) {
					[self.trackContainerArrayController setSortDescriptors:[NSSortDescriptor trackContainerSortDescriptorsForAlbumAscending:sortAscending]];
				} else if ([[tableColumn identifier] isEqualToString:@"artist"]) {
					[self.trackContainerArrayController setSortDescriptors:[NSSortDescriptor trackContainerSortDescriptorsForArtistAscending:sortAscending]];
				}
				[(SPTableHeaderCell *)[col headerCell] setSortAscending:[[[self.trackContainerArrayController sortDescriptors] objectAtIndex:0] ascending] priority:0];
			} else {
				[(SPTableHeaderCell *)[col headerCell] setSortAscending:YES priority:1];
			}
			
			[[self.trackTable headerView] setNeedsDisplay:YES];
		}
	}
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	
	if ([[aTableColumn identifier] isEqualToString:@"playIndicator"]) {
		if (rowIndex < [[self.trackContainerArrayController arrangedObjects] count]) {
			id <VivaTrackContainer> container = [[self.trackContainerArrayController arrangedObjects] objectAtIndex:rowIndex];
			if (container == self.playingTrackContainer) {
				if (self.playingTrackContainerIsCurrentlyPlaying) {
					[aCell setImage:[NSImage imageNamed:@"playing-indicator"]];
					[aCell setAlternateImage:[NSImage imageNamed:@"playing-indicator-highlighted"]];
				} else {
					[aCell setImage:[NSImage imageNamed:@"paused-indicator"]];
					[aCell setAlternateImage:[NSImage imageNamed:@"paused-indicator-highlighted"]];
				}
			} else {
				[aCell setImage:nil];
				[aCell setAlternateImage:nil];
			}
		}
	}	
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	
	NSArray *containers = [self.trackContainerArrayController.arrangedObjects objectsAtIndexes:rowIndexes];
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:[[containers valueForKey:@"track"] valueForKey:@"spotifyURL"]]
			forType:kSpotifyTrackURLListDragIdentifier];
	
	NSMutableIndexSet *sourceIndexes = [NSMutableIndexSet indexSet];
	for (id <VivaTrackContainer> ref in containers) {
		[sourceIndexes addIndex:[self.trackContainers indexOfObject:ref]];
	}
	
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:sourceIndexes]
			forType:kSpotifyTrackMoveSourceIndexSetDragIdentifier];
	
	return YES;
}

- (void)dealloc {
	self.trackContainers = nil;
	[self removeObserver:self forKeyPath:@"playingTrackContainerIsCurrentlyPlaying"];
	[self removeObserver:self forKeyPath:@"playingTrackContainer"];
    [super dealloc];
}

@end
