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
#import "SPPlaylistDelegateProxy.h"

@interface PlaylistViewController ()

@property (nonatomic, readwrite, strong) SPPlaylist *playlist;
@property (nonatomic, readwrite, strong) SPPlaylistDelegateProxy *playlistProxy;

-(void)rebuildTrackContainers;
-(NSArray *)trackSnapshot;

@end

@implementation PlaylistViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	return [self initWithObjectFromURL:aURL nibName:@"PlaylistViewController"];
}

-(id)initWithObjectFromURL:(NSURL *)aURL nibName:(NSString *)nibName {
	
	if (self = [super initWithObjectFromURL:aURL nibName:nibName]) {
		[self addObserver:self
			   forKeyPath:@"playlist.items"
				  options:0
				  context:nil];
		
		self.playlistProxy = [[SPPlaylistDelegateProxy alloc] initWithProxyReceiver:self];
		
		self.playlist = [[SPSession sharedSession] playlistForURL:aURL];
		self.playlist.delegate = self.playlistProxy;
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
    if ([keyPath isEqualToString:@"playlist.items"]) {
        
		NSArray *containerTracks = [self.trackContainers valueForKey:@"track"];
		if (![containerTracks isEqualToArray:self.trackSnapshot]) {
			[self rebuildTrackContainers];
		}
		
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(NSArray *)trackSnapshot {
	NSMutableArray *trackArray = [NSMutableArray arrayWithCapacity:[self.playlist.items count]];
	
	for (SPPlaylistItem *anItem in self.playlist.items) {
		if ([[anItem itemClass] isKindOfClass:[SPTrack class]])
			[trackArray addObject:anItem.item];
	}
	return [NSArray arrayWithArray:trackArray];
}

-(void)rebuildTrackContainers {
	
	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[self.playlist.items count]];
	
	for (SPPlaylistItem *anItem in self.playlist.items) {
		
		if ([anItem.item isKindOfClass:[SPTrack class]])
			[newContainers addObject:[[VivaTrackInContainerReference alloc] initWithTrack:[anItem item]
																			   inContainer:self.playlist]];
	}
	self.trackContainers = [NSMutableArray arrayWithArray:newContainers];
}

@synthesize playlist;
@synthesize playlistProxy;

-(void)deleteBackward:(id)sender {
	
	if (self.trackContainerArrayController.selectedObjects.count == 0) {
		NSBeep();
		return;
	}
	[self.playlist.items removeObjectsAtIndexes:self.trackContainerArrayController.selectionIndexes];
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
		[newContainers addObject:[[VivaTrackInContainerReference alloc] initWithTrack:newTrack
																		   inContainer:self.playlist]];
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
			NSArray *tracksToMove = [self.playlist.items objectsAtIndexes:trackIndexesToMove];
			[self.playlist.items insertObjects:tracksToMove 
									 atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [tracksToMove count])]];
			
		} else {
			[self.playlist moveItemsAtIndexes:trackIndexesToMove toIndex:row error:nil];
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
		
		[self.playlist.items insertObjects:tracksToAdd 
								 atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [tracksToAdd count])]];
		return YES;
	}
	
	return NO;
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"playlist.items"];
}

@end
