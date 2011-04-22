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
}

@synthesize trackContainerArrayController;
@synthesize trackTable;

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

- (void)dealloc
{
    [super dealloc];
}

@end
