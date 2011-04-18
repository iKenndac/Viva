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
#import "Constants.h"
#import "VivaImageExtensions.h"

@interface PlaylistViewController ()

@property (nonatomic, readwrite, retain) SPSpotifyPlaylist *playlist;
@property (nonatomic, readwrite, retain) NSMutableArray *trackContainers;

-(void)rebuildTrackContainers;

@end

@implementation PlaylistViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	if ((self = [super initWithObjectFromURL:aURL])) {
		
		[self addObserver:self
			   forKeyPath:@"playlist.tracks"
				  options:0
				  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"playingTrackContainer"
				  options:0
				  context:nil];
		
		[self addObserver:self 
			   forKeyPath:@"playingTrackContainerIsCurrentlyPlaying"
				  options:0
				  context:nil];
		
		self.playlist = [[(VivaAppDelegate *)[NSApp delegate] session] playlistForURL:aURL];
		self.playlist.delegate = self;
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
	
	[self.trackTable setDraggingSourceOperationMask:NSDragOperationNone forLocal:NO];
	[self.trackTable setDraggingSourceOperationMask:NSDragOperationMove | NSDragOperationCopy forLocal:YES];
	[self.trackTable registerForDraggedTypes:[NSArray arrayWithObjects:kSpotifyTrackURLListDragIdentifier, kSpotifyTrackMoveSourceIndexSetDragIdentifier, nil]];
	[self.trackTable setTarget:self];
	[self.trackTable setDoubleAction:@selector(playTrack:)];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"playlist.tracks"]) {
        
		NSArray *containerTracks = [self.trackContainers valueForKey:@"track"];
		if (![containerTracks isEqualToArray:self.playlist.tracks]) {
			NSLog(@"Containers not in sync with tracks - rebuilding.");
			[self rebuildTrackContainers];
		}
		
	} else if ([keyPath isEqualToString:@"playingTrackContainer"] || [keyPath isEqualToString:@"playingTrackContainerIsCurrentlyPlaying"]) {
		[self.trackTable reloadData];
		if (self.playingTrackContainer != nil)
			[self.trackTable scrollRowToVisible:[self.trackContainerArrayController.arrangedObjects indexOfObject:self.playingTrackContainer]];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)rebuildTrackContainers {

	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[[self.playlist mutableArrayValueForKey:@"tracks"] count]];
	
	for (SPSpotifyTrack *aTrack in [self.playlist mutableArrayValueForKey:@"tracks"]) {
		[newContainers addObject:[[[VivaTrackInPlaylistReference alloc] initWithTrack:aTrack
																		   inPlaylist:self.playlist] autorelease]];
	}
	self.trackContainers = [NSMutableArray arrayWithArray:newContainers];
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

-(void)keyDown:(NSEvent *)theEvent {
	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

-(void)deleteBackward:(id)sender {
	
	if (self.trackContainerArrayController.selectedObjects.count == 0) {
		NSBeep();
		return;
	}
	
	[self.playlist.tracks removeObjectsAtIndexes:self.trackContainerArrayController.selectionIndexes];
}

#pragma mark -

+(NSSet *)keyPathsForValuesAffectingTrackContainersForPlayback {
	return [NSSet setWithObject:@"trackContainers"];
}

-(void)playlist:(SPSpotifyPlaylist *)aPlaylist willRemoveTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)outgoingIndexes {
	
	[self willChangeValueForKey:@"trackContainers"];
	[self.trackContainers removeObjectsAtIndexes:outgoingIndexes];
	[self didChangeValueForKey:@"trackContainers"];
}

-(void)playlist:(SPSpotifyPlaylist *)aPlaylist didRemoveTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)theseIndexesArentValidAnymore; {}

-(void)playlist:(SPSpotifyPlaylist *)aPlaylist willAddTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)theseIndexesArentYetValid {
	
	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[tracks count]];
	
	for (SPSpotifyTrack *newTrack in tracks) {
		[newContainers addObject:[[[VivaTrackInPlaylistReference alloc] initWithTrack:newTrack
																		   inPlaylist:self.playlist] autorelease]];
	}
	
	[self willChangeValueForKey:@"trackContainers"];
	[self.trackContainers insertObjects:newContainers atIndexes:theseIndexesArentYetValid];
	[self didChangeValueForKey:@"trackContainers"];
}

-(void)playlist:(SPSpotifyPlaylist *)aPlaylist didAddTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)newIndexes {}

-(void)playlist:(SPSpotifyPlaylist *)aPlaylist willMoveTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)oldIndexes toIndexes:(NSIndexSet *)newIndexes {

	[self willChangeValueForKey:@"trackContainers"];
	NSArray *transientContainers = [self.trackContainers objectsAtIndexes:oldIndexes];
	[self.trackContainers removeObjectsAtIndexes:oldIndexes];
	[self.trackContainers insertObjects:transientContainers atIndexes:newIndexes];
	[self didChangeValueForKey:@"trackContainers"];
}

-(void)playlist:(SPSpotifyPlaylist *)aPlaylist didMoveTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)oldIndexes toIndexes:(NSIndexSet *)newIndexes; {}


#pragma mark -

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

-(NSImage *)tableView:(NSTableView *)tableView dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent *)dragEvent offset:(NSPointPointer)dragImageOffset {
	
	return [NSImage decoratedMosaicWithTracks:[[self.trackContainerArrayController.arrangedObjects objectsAtIndexes:dragRows] valueForKey:@"track"]
								   badgeLabel:[dragRows count] > 1 ? [[NSNumber numberWithInteger:[dragRows count]] stringValue] : nil
											aspect:kDragImageMaximumMosaicSize];
	
}

#pragma mark -

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	
	NSArray *containers = [self.trackContainerArrayController.arrangedObjects objectsAtIndexes:rowIndexes];
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:[[containers valueForKey:@"track"] valueForKey:@"spotifyURL"]]
														forType:kSpotifyTrackURLListDragIdentifier];
	
	NSMutableIndexSet *sourceIndexes = [NSMutableIndexSet indexSet];
	for (VivaTrackInPlaylistReference *ref in containers) {
		[sourceIndexes addIndex:[self.trackContainers indexOfObject:ref]];
	}
	
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:sourceIndexes]
			forType:kSpotifyTrackMoveSourceIndexSetDragIdentifier];
	
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
	
	if ([self.trackContainerArrayController.sortDescriptors count] > 0)
		return NSDragOperationNone;
	
	NSData *dragData = nil;
	
	if ([info draggingSource] == self.trackTable) 
		dragData = [[info draggingPasteboard] dataForType:kSpotifyTrackMoveSourceIndexSetDragIdentifier];
	else
		dragData = [[info draggingPasteboard] dataForType:kSpotifyTrackURLListDragIdentifier];
	
	if (!dragData)
		return NSDragOperationNone;
	
	if (operation == NSTableViewDropOn)
		[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	
	if ([info draggingSource] == self.trackTable) {
		
		NSIndexSet *indexSet = [NSKeyedUnarchiver unarchiveObjectWithData:dragData];
		// Some heuristics to make dragging less annoying
		if ([indexSet count] == 1 && ([indexSet containsIndex:row] || [indexSet containsIndex:row-1]))
			// Don't let the user reorder their track to the same place 
			return NSDragOperationNone;
		
		return ([NSEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask ? NSDragOperationCopy : NSDragOperationMove;
	} else {
		return NSDragOperationCopy;
	}
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
	
	NSData *dragData = nil;
	
	if ([info draggingSource] == self.trackTable) 
		dragData = [[info draggingPasteboard] dataForType:kSpotifyTrackMoveSourceIndexSetDragIdentifier];
	else
		dragData = [[info draggingPasteboard] dataForType:kSpotifyTrackURLListDragIdentifier];
	
	if (!dragData)
		return NO;

	if ([info draggingSource] == self.trackTable) {
		
		NSIndexSet *trackIndexesToMove = [NSKeyedUnarchiver unarchiveObjectWithData:dragData];
		
		if (([NSEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask) {
			// Copy
			NSArray *tracksToMove = [self.playlist.tracks objectsAtIndexes:trackIndexesToMove];
			[self.playlist.tracks insertObjects:tracksToMove 
									  atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [tracksToMove count])]];

		} else {
			[self.playlist moveTracksAtIndexes:trackIndexesToMove toIndex:row];
		}
		
		return YES;
		
	} else {
		
		NSArray *trackURLs = [NSKeyedUnarchiver unarchiveObjectWithData:dragData];
		NSMutableArray *tracksToAdd = [NSMutableArray arrayWithCapacity:[trackURLs count]];
		
		for (NSURL *trackURL in trackURLs) {
			SPSpotifyTrack *track = [SPSpotifyTrack trackForTrackURL:trackURL inSession:self.playlist.session];
			if (track != nil) {
				[tracksToAdd addObject:track];
			}
		}
		
		[self.playlist.tracks insertObjects:tracksToAdd 
								  atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [tracksToAdd count])]];
		return YES;
	}
	
	return NO;
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"playlist.tracks"];
	[self removeObserver:self forKeyPath:@"playingTrackContainer"];
	[self removeObserver:self forKeyPath:@"playingTrackContainerIsCurrentlyPlaying"];
	self.trackContainers = nil;
	self.playlist = nil;
    [super dealloc];
}

@end
