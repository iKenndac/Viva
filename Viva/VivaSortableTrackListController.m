//
//  VivaSortableTrackListController.m
//  Viva
//
//  Created by Daniel Kennett on 4/22/11.
//  For license information, see LICENSE.markdown
//

#import "VivaSortableTrackListController.h"
#import "SPTableHeaderCell.h"
#import "SPTableCorner.h"
#import "VivaSortDescriptorExtensions.h"
#import "Constants.h"
#import "VivaImageExtensions.h"
#import "VivaTrackInContainerReference.h"
#import "VivaAppDelegate.h"

@implementation VivaSortableTrackListController

-(void)awakeFromNib {
	
	sortAscending = YES;
	
	// No IB support for custom headers. Yay!
	
	for (NSTableColumn *column in [self.trackTable tableColumns]) {
		SPTableHeaderCell *newCell = [[SPTableHeaderCell alloc] init];
		[newCell setObjectValue:[[column headerCell] objectValue]];
		[column setHeaderCell:newCell];
	}
	
	[self.trackTable setCornerView:[[SPTableCorner alloc] init]];
	
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

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if (menuItem.action == @selector(copySpotifyURI:)) {
		return self.trackTable.selectedRowIndexes.count == 1 || self.trackTable.clickedRow != -1;
	}
	return [super validateMenuItem:menuItem];
}

-(IBAction)copySpotifyURI:(id)sender {
	
	VivaTrackInContainerReference *item = nil;
	
	if (self.trackTable.clickedRow != -1) {
		item = [self.trackContainerArrayController.arrangedObjects objectAtIndex:self.trackTable.clickedRow];
	} else if (self.trackTable.selectedRowIndexes.count == 1) {
		item = [self.trackContainerArrayController.arrangedObjects objectAtIndex:self.trackTable.selectedRowIndexes.firstIndex];
	}
	
	if (item == nil) {
		NSBeep();
		return;
	}
	
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	
	[pasteboard declareTypes:[NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil] owner:nil];
	[pasteboard setString:item.track.spotifyURL.absoluteString forType:NSStringPboardType];
	[item.track.spotifyURL writeToPasteboard:pasteboard];
	
}

-(void)viewControllerDidActivateWithContext:(id)context {
	if ([context isKindOfClass:[SPTrack class]]) {
		
		for (id <VivaTrackContainer> container in self.trackContainerArrayController.arrangedObjects) {
			
			if ([container.track isEqual:context]) {
				[self.trackTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.trackContainerArrayController.arrangedObjects indexOfObject:container]] 
							 byExtendingSelection:NO];
				[self.trackTable becomeFirstResponder];
				return;
			}
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"playingTrackContainer"] || [keyPath isEqualToString:@"playingTrackContainerIsCurrentlyPlaying"]) {
		[self.trackTable reloadData];
		if (self.playingTrackContainer != nil) {
            
            NSInteger rowIndex = [self.trackContainerArrayController.arrangedObjects indexOfObject:self.playingTrackContainer];
            NSRect rowRect = [self.trackTable rectOfRow:rowIndex];
            
            if (!NSContainsRect([self.trackTable visibleRect], rowRect))
                [self.trackTable scrollRowToVisible:rowIndex];
        }
			
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)keyDown:(NSEvent *)theEvent {
	
	if ([[theEvent characters] isEqualToString:@" "]) {
		[[[NSApp delegate] playbackManager] setPlaying:![[[NSApp delegate] playbackManager] isPlaying]];
	} else {
		[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
	}
}

-(void)insertNewline:(id)sender {
	
	if (self.trackTable.window.firstResponder == self.trackTable) {
		if (self.trackContainerArrayController.selectedObjects.count > 0) {
			id <VivaTrackContainer> container = [[self.trackContainerArrayController selectedObjects] objectAtIndex:0];
			[self playTrackContainerInThisContext:container];
			return;
		}
	}
	NSBeep();
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

-(void)setPlayingTrackContainer:(id <VivaTrackContainer>)aTrackContainer isPlaying:(BOOL)playing {
	[super setPlayingTrackContainer:aTrackContainer isPlaying:playing];
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
	} else {
        
        if (rowIndex < [[self.trackContainerArrayController arrangedObjects] count]) {
			id <VivaTrackContainer> container = [[self.trackContainerArrayController arrangedObjects] objectAtIndex:rowIndex];
			[aCell setEnabled:(container.track.availability == SP_TRACK_AVAILABILITY_AVAILABLE ||
							   container.track.isLocal)];
        }
    }
}

-(NSImage *)tableView:(NSTableView *)tableView dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent *)dragEvent offset:(NSPointPointer)dragImageOffset {
	
	return [NSImage decoratedMosaicWithTracks:[[self.trackContainerArrayController.arrangedObjects objectsAtIndexes:dragRows] valueForKey:@"track"]
								   badgeLabel:[dragRows count] > 1 ? [[NSNumber numberWithInteger:[dragRows count]] stringValue] : nil
									   aspect:kDragImageMaximumMosaicSize];
	
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
	[self removeObserver:self forKeyPath:@"playingTrackContainerIsCurrentlyPlaying"];
	[self removeObserver:self forKeyPath:@"playingTrackContainer"];
}

@end
