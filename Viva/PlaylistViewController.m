//
//  PlaylistViewController.m
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "PlaylistViewController.h"
#import "VivaAppDelegate.h"
#import "VivaTrackInContainerReference.h"
#import "Constants.h"

@interface PlaylistViewController ()

@property (nonatomic, readwrite, retain) SPPlaylist *playlist;

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
		self.playlist.delegate = self;
	}
	return self;
}

-(void)awakeFromNib {

	[super awakeFromNib];
	
	[self.trackTable setDraggingSourceOperationMask:NSDragOperationNone forLocal:NO];
	[self.trackTable setDraggingSourceOperationMask:NSDragOperationMove | NSDragOperationCopy forLocal:YES];
	[self.trackTable registerForDraggedTypes:[NSArray arrayWithObjects:kSpotifyTrackURLListDragIdentifier, kSpotifyTrackMoveSourceIndexSetDragIdentifier, nil]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"playlist.tracks"]) {
        
		NSArray *containerTracks = [self.trackContainers valueForKey:@"track"];
		if (![containerTracks isEqualToArray:self.playlist.tracks]) {
			NSLog(@"Containers not in sync with tracks - rebuilding.");
			[self rebuildTrackContainers];
		}
		
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)rebuildTrackContainers {

	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[self.playlist.tracks count]];
	
	for (SPTrack *aTrack in self.playlist.tracks) {
		[newContainers addObject:[[[VivaTrackInContainerReference alloc] initWithTrack:aTrack
																		   inContainer:self.playlist] autorelease]];
	}
	self.trackContainers = [NSMutableArray arrayWithArray:newContainers];
}

@synthesize playlist;

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

-(void)playlist:(SPPlaylist *)aPlaylist willRemoveTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)outgoingIndexes {
	
	[self willChangeValueForKey:@"trackContainers"];
	[self.trackContainers removeObjectsAtIndexes:outgoingIndexes];
	[self didChangeValueForKey:@"trackContainers"];
}

-(void)playlist:(SPPlaylist *)aPlaylist didRemoveTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)theseIndexesArentValidAnymore; {}

-(void)playlist:(SPPlaylist *)aPlaylist willAddTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)theseIndexesArentYetValid {
	
	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[tracks count]];
	
	for (SPTrack *newTrack in tracks) {
		[newContainers addObject:[[[VivaTrackInContainerReference alloc] initWithTrack:newTrack
																		   inContainer:self.playlist] autorelease]];
	}
	
	[self willChangeValueForKey:@"trackContainers"];
	[self.trackContainers insertObjects:newContainers atIndexes:theseIndexesArentYetValid];
	[self didChangeValueForKey:@"trackContainers"];
}

-(void)playlist:(SPPlaylist *)aPlaylist didAddTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)newIndexes {}

-(void)playlist:(SPPlaylist *)aPlaylist willMoveTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)oldIndexes toIndexes:(NSIndexSet *)newIndexes {

	[self willChangeValueForKey:@"trackContainers"];
	NSArray *transientContainers = [self.trackContainers objectsAtIndexes:oldIndexes];
	[self.trackContainers removeObjectsAtIndexes:oldIndexes];
	[self.trackContainers insertObjects:transientContainers atIndexes:newIndexes];
	[self didChangeValueForKey:@"trackContainers"];
}

-(void)playlist:(SPPlaylist *)aPlaylist didMoveTracks:(NSArray *)tracks atIndexes:(NSIndexSet *)oldIndexes toIndexes:(NSIndexSet *)newIndexes; {}

#pragma mark -

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
			[self.playlist moveTracksAtIndexes:trackIndexesToMove toIndex:row error:nil];
		}
		
		return YES;
		
	} else {
		
		NSArray *trackURLs = [NSKeyedUnarchiver unarchiveObjectWithData:dragData];
		NSMutableArray *tracksToAdd = [NSMutableArray arrayWithCapacity:[trackURLs count]];
		
		for (NSURL *trackURL in trackURLs) {
			SPTrack *track = [SPTrack trackForTrackURL:trackURL inSession:self.playlist.session];
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
	self.playlist = nil;
    [super dealloc];
}

@end
