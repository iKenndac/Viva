//
//  MainWindowSidebarController.m
//  Viva
//
//  Created by Daniel Kennett on 6/20/11.
//  For license information, see LICENSE.markdown
//

#import "MainWindowSidebarController.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaInternalURLManager.h"
#import "VivaPlaybackContext.h"
#import "Constants.h"
#import "VivaSourceListRowView.h"

@interface MainWindowSidebarController ()

@property (readwrite, copy, nonatomic) NSArray *groups;
@property (readwrite, copy, nonatomic) NSArray *pinnedItems;

-(NSDictionary *)unifiedDictionaryForItem:(id)item;
-(NSInteger)indexOfPinnedItemInOutlineView:(id)playlistOrFolder;
-(NSInteger)realIndexOfPinnedItemAtIndexInOutlineView:(NSInteger)playlistOrFolderIndex;

@end

@implementation MainWindowSidebarController

-(id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
		
		id propertyList = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BaseSidebarConfiguration" ofType:@"plist"]]
																	options:0
																	 format:NULL
																	  error:nil];
		
		self.groups = [propertyList valueForKey:@"Groups"];
		
		[self addObserver:self
			   forKeyPath:@"pinnedItems"
				  options:0
				  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"selectedURL"
				  options:0
				  context:nil];
        
        [self addObserver:self
			   forKeyPath:@"sidebar"
				  options:0
				  context:nil];

		NSArray *urlStrings = [[NSUserDefaults standardUserDefaults] valueForKey:kVivaPinnedItemsUserDefaultsKey];

		dispatch_async([SPSession libSpotifyQueue], ^{

			NSMutableArray *mutableItems = [NSMutableArray arrayWithCapacity:urlStrings.count];
			for (NSString *itemURLString in urlStrings) {

				id item = [[SPSession sharedSession] objectRepresentationForSpotifyURL:[NSURL URLWithString:itemURLString] linkType:NULL];
				if (item)
					[mutableItems addObject:item];
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				self.pinnedItems = [NSArray arrayWithArray:mutableItems];
			});
		});
    }
    
    return self;
}

@synthesize groups;
@synthesize sidebar;
@synthesize selectedURL;

-(void)outlineViewItemDoubleClicked:(id)sender {
    
    id item = [self unifiedDictionaryForItem:[self.sidebar itemAtRow:self.sidebar.clickedRow]];
    NSURL *url = [item valueForKey:SPSidebarURLKey];
    
    if (!url) return;
    id controller = [[VivaInternalURLManager sharedInstance] viewControllerForURL:url];
    
    if ([controller conformsToProtocol:@protocol(VivaPlaybackContext)]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTrackShouldBePlayedNotification
                                                            object:controller
                                                          userInfo:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"pinnedItems"]) {
		[self.sidebar reloadData];

		[SPAsyncLoading waitUntilLoaded:self.pinnedItems timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *loadedItems, NSArray *notLoadedItems) {
			NSArray *urls = [self.pinnedItems valueForKey:@"spotifyURL"];
			if ([urls containsObject:[NSNull null]]) return; //Bail!
			[[NSUserDefaults standardUserDefaults] setValue:[urls valueForKey:@"absoluteString"] forKey:kVivaPinnedItemsUserDefaultsKey];
		}];
		
	} else if ([keyPath isEqualToString:@"selectedURL"]) {
		
		for (id group in self.groups) {
			for (id currentItem in [group valueForKey:kSPSidebarGroupItemsKey]) {
					
				NSDictionary *dict = [self unifiedDictionaryForItem:currentItem];
				if ([[dict valueForKey:SPSidebarURLKey] isEqual:self.selectedURL]) {
					NSInteger row = [self.sidebar rowForItem:currentItem];
					[self.sidebar selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
					return;
				}
							
				if ([[currentItem valueForKey:kSPSidebarItemTitleKey] isEqualToString:kSPSidebarItemUserPlaylistsPlaceholderTitle]) {
					
					[[SPSession sharedSession] playlistForURL:self.selectedURL
													 callback:^(SPPlaylist *playlist) {
														 if (playlist != nil) {
															 NSInteger row = [self.sidebar rowForItem:playlist];
															 [self.sidebar selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
															 return;
														 } else {
															 [self.sidebar selectRowIndexes:nil byExtendingSelection:NO];
														 }
													 }];
				}
			}
		}
		
		// If we get here, the current URL is something we're not displaying!
		[self.sidebar selectRowIndexes:nil byExtendingSelection:NO];
		
    } else if ([keyPath isEqualToString:@"sidebar"]) {
        self.sidebar.target = self;
        self.sidebar.doubleAction = @selector(outlineViewItemDoubleClicked:);
        
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"pinnedItems"];
	[self removeObserver:self forKeyPath:@"selectedURL"];
	[self removeObserver:self forKeyPath:@"sidebar"];
	self.sidebar = nil;
}

-(NSDictionary *)unifiedDictionaryForItem:(id)item {
	
	if ([item isKindOfClass:[SPPlaylist class]]) {
		SPPlaylist *playlist = item;
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSImage imageNamed:@"sidebar-playlist"], SPSidebarImageKey,
				playlist, SPSidebarOriginalItemKey,
				playlist.spotifyURL, SPSidebarURLKey,
				nil];
		
	} else if ([item isKindOfClass:[SPAlbum class]]) {
		SPAlbum *album = item;
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSImage imageNamed:@"sidebar-folder"], SPSidebarImageKey,
				album, SPSidebarOriginalItemKey,
				album.spotifyURL, SPSidebarURLKey,
				nil];

	} else if ([item isKindOfClass:[SPArtist class]]) {
		SPArtist *artist = item;
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSImage imageNamed:@"sidebar-folder"], SPSidebarImageKey,
				artist, SPSidebarOriginalItemKey,
				artist.spotifyURL, SPSidebarURLKey,
				nil];

	} else if ([item isKindOfClass:[SPPlaylistFolder class]]) {
		SPPlaylistFolder *folder = item;
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSImage imageNamed:@"sidebar-folder"], SPSidebarImageKey,
				folder, SPSidebarOriginalItemKey,
				nil];
		
	} else if ([item valueForKey:kSPSidebarGroupIdentifierKey]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[item valueForKey:kSPSidebarGroupTitleKey], SPSidebarTitleKey,
				nil];
		
	} else if ([item valueForKey:kSPSidebarItemTitleKey]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[item valueForKey:kSPSidebarItemTitleKey], SPSidebarTitleKey,
				[NSImage imageNamed:[item valueForKey:kSPSidebarItemImageKeyKey]], SPSidebarImageKey,
				[NSURL URLWithString:[item valueForKey:kSPSidebarItemSpotifyURLKey]], SPSidebarURLKey, 
				nil];
	}
	
	return nil;
}

-(NSInteger)realIndexOfPinnedItemAtIndexInOutlineView:(NSInteger)playlistOrFolderIndex {
	
	NSInteger currentIndex = 0;
	
	for (id group in self.groups) {
		if ([[group valueForKey:kSPSidebarGroupTitleIsShownKey] boolValue]) {
			currentIndex++;
		}
		
		for (id currentItem in [group valueForKey:kSPSidebarGroupItemsKey]) {
			if ([[currentItem valueForKey:kSPSidebarItemTitleKey] isEqualToString:kSPSidebarItemUserPlaylistsPlaceholderTitle]) {
				// Here be items!
				return playlistOrFolderIndex - currentIndex;
			} else {
				currentIndex++;
			}
		}
	}
	
	return NSNotFound;
}

-(NSInteger)indexOfPinnedItemInOutlineView:(id)pinnedItem {
	
	NSInteger currentIndex = 0;
	
	for (id group in self.groups) {
		if ([[group valueForKey:kSPSidebarGroupTitleIsShownKey] boolValue]) {
			currentIndex++;
		}
		
		for (id currentItem in [group valueForKey:kSPSidebarGroupItemsKey]) {
			if ([[currentItem valueForKey:kSPSidebarItemTitleKey] isEqualToString:kSPSidebarItemUserPlaylistsPlaceholderTitle]) {
				// Here be playlists!
				NSUInteger indexOfItem = [self.pinnedItems indexOfObject:pinnedItem];
				if (indexOfItem != NSNotFound)
					return currentIndex + indexOfItem;
				else
					return NSNotFound;
			} else {
				currentIndex++;
			}
		}
	}
	
	return NSNotFound;
}

#pragma mark -

-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	
	NSTableCellView *view = nil;
	if ([item isKindOfClass:[NSDictionary class]] && [[item valueForKey:kSPSidebarGroupTitleIsShownKey] boolValue])
		view = [outlineView makeViewWithIdentifier:@"SectionHeaderCell" owner:self];
	else
		view = [outlineView makeViewWithIdentifier:@"ImageAndTextCell" owner:self];
	
	if ([item isKindOfClass:[SPPlaylist class]] || [item isKindOfClass:[SPPlaylistFolder class]]) {
		view.textField.editable = YES;
	} else {
		view.textField.editable = NO;
	}
	
	return view;
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item {
	return [[VivaSourceListRowView alloc] init];
}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
	NSDictionary *itemDict = [self unifiedDictionaryForItem:item];
	return [itemDict valueForKey:SPSidebarURLKey] != nil;
}

#pragma mark -

-(void)outlineViewSelectionDidChange:(NSNotification *)aNotification {
	
	if (self.sidebar.selectedRowIndexes.count > 0) {
		id item = [self.sidebar itemAtRow:self.sidebar.selectedRow];
		NSDictionary *itemDict = [self unifiedDictionaryForItem:item];
		// Remove our internal observer so we don't infinite loop ourselves.
		[self removeObserver:self forKeyPath:@"selectedURL"];
		self.selectedURL = [itemDict valueForKey:SPSidebarURLKey];
		[self addObserver:self forKeyPath:@"selectedURL" options:0 context:nil];
	}
}

#pragma mark -

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	
	if (item == nil) {
		// Root
		// We aren't treating groups as expandable items.
		
		NSInteger itemCount = 0;
		
		for (id group in self.groups) {
			if ([[group valueForKey:kSPSidebarGroupTitleIsShownKey] boolValue])
				itemCount++;
			
			for (id item in [group valueForKey:kSPSidebarGroupItemsKey]) {
				if ([[item valueForKey:kSPSidebarItemTitleKey] isEqualToString:kSPSidebarItemUserPlaylistsPlaceholderTitle])
					itemCount += self.pinnedItems.count;
				else
					itemCount++;
			}
		}
		return itemCount;
		
	} else if ([item isKindOfClass:[SPPlaylistFolder class]]) {
		return [[(SPPlaylistFolder *)item playlists] count];
	}
	
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return [item isKindOfClass:[SPPlaylistFolder class]];
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
	return NO; //[item isKindOfClass:[NSDictionary class]] && [[item valueForKey:SPGroupTitleIsShownKey] boolValue];
}

-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	return [self unifiedDictionaryForItem:item];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	
	if (item == nil) {
		// Root
		// We aren't treating groups as expandable items.
		
		NSInteger currentIndex = 0;
		
		for (id group in self.groups) {
			
			if ([[group valueForKey:kSPSidebarGroupTitleIsShownKey] boolValue] && currentIndex == index) {
				return group;
			} else if ([[group valueForKey:kSPSidebarGroupTitleIsShownKey] boolValue]) {
				currentIndex++;
			}
			
			for (id currentItem in [group valueForKey:kSPSidebarGroupItemsKey]) {
				
				if ([[currentItem valueForKey:kSPSidebarItemTitleKey] isEqualToString:kSPSidebarItemUserPlaylistsPlaceholderTitle]) {
					
					NSInteger pinnedCount = self.pinnedItems.count;
					NSInteger relativeIndex = index - currentIndex;
					
					if (relativeIndex < pinnedCount) {
						id childItem = [self.pinnedItems objectAtIndex:relativeIndex];
						return childItem;
					} else {
						currentIndex += pinnedCount;
					}
				} else if (currentIndex == index) {
					return currentItem;
				} else {
					currentIndex++;
				}
			}
		}
	} else if ([item isKindOfClass:[SPPlaylistFolder class]]) {
		return [[(SPPlaylistFolder *)item playlists] objectAtIndex:index];
	}
	
	return nil;
}

#pragma mark -

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	return YES;
}

#pragma mark -

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView
				  validateDrop:(id < NSDraggingInfo >)info
				  proposedItem:(id)item
			proposedChildIndex:(NSInteger)index {

	NSData *trackUrlData = [[info draggingPasteboard] dataForType:kSpotifyTrackURLListDragIdentifier];

	if (trackUrlData != nil) {
		if ((![item isKindOfClass:[SPPlaylist class]]) ||
			([item isKindOfClass:[SPPlaylistFolder class]])) {
			return NSDragOperationNone;
		} else {
			return NSDragOperationCopy;
		}
	}

	NSData *itemUrlData = [[info draggingPasteboard] dataForType:kSpotifyItemReferenceDragIdentifier];

	if (itemUrlData != nil) {

		NSURL *itemURL = [[NSKeyedUnarchiver unarchiveObjectWithData:itemUrlData] valueForKey:kItemReferenceURL];
		if ([[self.pinnedItems valueForKey:@"spotifyURL"] containsObject:itemURL])
			return NSDragOperationNone;
		
		if (item == nil) {
			NSInteger indexOfFirstItem = [self indexOfPinnedItemInOutlineView:[self.pinnedItems objectAtIndex:0]];
			NSInteger indexOfLastItem = [self indexOfPinnedItemInOutlineView:self.pinnedItems.lastObject];

			if (index == -1 && self.pinnedItems.count > 0)
				index = indexOfLastItem + 1;

			[outlineView setDropItem:nil
					  dropChildIndex:index < indexOfFirstItem ? indexOfFirstItem : index > indexOfLastItem ? indexOfLastItem + 1 : index];

			return NSDragOperationCopy;

		} else {
			[outlineView setDropItem:nil
					  dropChildIndex:[self realIndexOfPinnedItemAtIndexInOutlineView:0]];

			return NSDragOperationMove;
		}

	}

	return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index {

	NSData *urlData = [[info draggingPasteboard] dataForType:kSpotifyTrackURLListDragIdentifier];

	if (urlData != nil) {

		dispatch_async([SPSession libSpotifyQueue], ^{

			NSArray *trackURLs = [NSKeyedUnarchiver unarchiveObjectWithData:urlData];
			NSMutableArray *tracksToAdd = [NSMutableArray arrayWithCapacity:[trackURLs count]];

			for (NSURL *url in trackURLs) {

				SPTrack *track = nil;
				sp_link *link = [url createSpotifyLink];

				if (link != NULL && sp_link_type(link) == SP_LINKTYPE_TRACK) {
					sp_track *tr = sp_link_as_track(link);
					track = [SPTrack trackForTrackStruct:tr inSession:[SPSession sharedSession]];
					sp_link_release(link);
				}

				if (track != nil) {
					[tracksToAdd addObject:track];
				}
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				SPPlaylist *targetPlaylist = [item representedObject];
				[targetPlaylist addItems:tracksToAdd atIndex:targetPlaylist.items.count callback:^(NSError *error) {
					if (error) [self.sidebar.window presentError:error];
				}];
			});
		});
		
		return YES;
	}

	NSData *itemUrlData = [[info draggingPasteboard] dataForType:kSpotifyItemReferenceDragIdentifier];

	if (itemUrlData != nil) {

		NSInteger insertIndex = [self realIndexOfPinnedItemAtIndexInOutlineView:index];
		NSURL *itemURL = [[NSKeyedUnarchiver unarchiveObjectWithData:itemUrlData] valueForKey:kItemReferenceURL];

		NSMutableArray *newItems = [NSMutableArray arrayWithArray:self.pinnedItems];

		[[SPSession sharedSession] objectRepresentationForSpotifyURL:itemURL callback:^(sp_linktype linkType, id objectRepresentation) {
			if (objectRepresentation) {
				[newItems insertObject:objectRepresentation atIndex:insertIndex];
				self.pinnedItems = [NSArray arrayWithArray:newItems];
			}
		}];

		return YES;
	}

	return NO;


}




@end
