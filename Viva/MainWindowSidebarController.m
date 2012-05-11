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

-(NSDictionary *)unifiedDictionaryForItem:(id)item;
-(NSInteger)indexOfRootPlaylistInOutlineView:(id)playlistOrFolder;
-(NSInteger)realIndexOfRootPlaylistAtIndexInOutlineView:(NSInteger)playlistOrFolderIndex;

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
		
		[[SPSession sharedSession] addObserver:self
									forKeyPath:@"userPlaylists.playlists"
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
    if ([keyPath isEqualToString:@"userPlaylists.playlists"]) {
		[self.sidebar reloadData];
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
	[[SPSession sharedSession] removeObserver:self forKeyPath:@"userPlaylists.playlists"];
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

-(NSInteger)realIndexOfRootPlaylistAtIndexInOutlineView:(NSInteger)playlistOrFolderIndex {
	
	NSInteger currentIndex = 0;
	
	for (id group in self.groups) {
		if ([[group valueForKey:kSPSidebarGroupTitleIsShownKey] boolValue]) {
			currentIndex++;
		}
		
		for (id currentItem in [group valueForKey:kSPSidebarGroupItemsKey]) {
			if ([[currentItem valueForKey:kSPSidebarItemTitleKey] isEqualToString:kSPSidebarItemUserPlaylistsPlaceholderTitle]) {
				// Here be playlists!
				return playlistOrFolderIndex - currentIndex;
			} else {
				currentIndex++;
			}
		}
	}
	
	return NSNotFound;
}

-(NSInteger)indexOfRootPlaylistInOutlineView:(id)playlistOrFolder {
	
	NSInteger currentIndex = 0;
	
	for (id group in self.groups) {
		if ([[group valueForKey:kSPSidebarGroupTitleIsShownKey] boolValue]) {
			currentIndex++;
		}
		
		for (id currentItem in [group valueForKey:kSPSidebarGroupItemsKey]) {
			if ([[currentItem valueForKey:kSPSidebarItemTitleKey] isEqualToString:kSPSidebarItemUserPlaylistsPlaceholderTitle]) {
				// Here be playlists!
				NSUInteger indexOfPlaylist = [[SPSession sharedSession].userPlaylists.playlists indexOfObject:playlistOrFolder];
				if (indexOfPlaylist != NSNotFound)
					return currentIndex + indexOfPlaylist;
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
					itemCount += [SPSession sharedSession].userPlaylists.playlists.count;
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
					
					NSInteger playlistCount = [SPSession sharedSession].userPlaylists.playlists.count;
					NSInteger relativeIndex = index - currentIndex;
					
					if (relativeIndex < playlistCount) {
						id childItem = [[SPSession sharedSession].userPlaylists.playlists objectAtIndex:relativeIndex];
						return childItem;
					} else {
						currentIndex += playlistCount;
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

#pragma mark - Drag & Drop

// What follows is likely the worst code you've ever seen. I'm *really* sorry. --Dan

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
	
	NSData *playlistSourceData = [[info draggingPasteboard] dataForType:kSpotifyPlaylistMoveSourceDragIdentifier];
	NSData *folderSourceData = [[info draggingPasteboard] dataForType:kSpotifyFolderMoveSourceDragIdentifier];
	
	BOOL isFolder = (playlistSourceData == nil && folderSourceData != nil);
	
	NSDictionary *sourceFolderInfo = nil;
	sp_uint64 folderId = 0;
	SPPlaylistContainer *userPlaylists = nil;
	__block SPPlaylistFolder *sourceFolder = nil;
	
	if (isFolder) {
		sourceFolderInfo = [NSKeyedUnarchiver unarchiveObjectWithData:folderSourceData];
		folderId = [[sourceFolderInfo valueForKey:kFolderId] unsignedLongLongValue];
		userPlaylists = [[SPSession sharedSession] userPlaylists];
		
		SPDispatchSyncIfNeeded(^{
			sourceFolder =  [[SPSession sharedSession] playlistFolderForFolderId:folderId
																	 inContainer:userPlaylists];

		});
	}

	if (item == nil) {
		NSInteger indexOfFirstPlaylist = [self indexOfRootPlaylistInOutlineView:[[SPSession sharedSession].userPlaylists.playlists objectAtIndex:0]];
		NSInteger indexOfLastPlaylist = [self indexOfRootPlaylistInOutlineView:[SPSession sharedSession].userPlaylists.playlists.lastObject];
		
		[outlineView setDropItem:nil
				  dropChildIndex:index < indexOfFirstPlaylist ? indexOfFirstPlaylist : index > indexOfLastPlaylist ? indexOfLastPlaylist + 1 : index];
		
		return NSDragOperationMove;
		
	} else if ([item isKindOfClass:[SPPlaylistFolder class]]) {
		
		if (isFolder && ([[item parentFolders] containsObject:sourceFolder] || item == sourceFolder))
			return NSDragOperationNone;
		// ^ Can't put a folder into itself
		
		return NSDragOperationMove;
		
	} else if ([item isKindOfClass:[SPPlaylist class]]) {
		
		SPPlaylistFolder *parent = [outlineView parentForItem:item];
		
		if (isFolder && ([[parent parentFolders] containsObject:sourceFolder] || parent == sourceFolder))
			return NSDragOperationNone;
		// ^ Can't put a folder into itself
		
		[outlineView setDropItem:[outlineView parentForItem:item] 
				  dropChildIndex:parent != nil ? [[parent playlists] indexOfObject:item] : 
		 [self indexOfRootPlaylistInOutlineView:item]];
		
		return NSDragOperationMove;
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
				SPPlaylist *targetPlaylist = item;
				[targetPlaylist addItems:tracksToAdd atIndex:targetPlaylist.items.count callback:^(NSError *error) {
					if (error) [self.sidebar.window presentError:error];
				}];
			});
		});
		
		return YES;
	}
	
	NSData *playlistUrlData = [[info draggingPasteboard] dataForType:kSpotifyPlaylistMoveSourceDragIdentifier];
	NSData *folderSourceData = [[info draggingPasteboard] dataForType:kSpotifyFolderMoveSourceDragIdentifier];
	
	BOOL isFolder = (playlistUrlData == nil && folderSourceData != nil);
	SPPlaylistContainer *userPlaylists = [[SPSession sharedSession] userPlaylists];
	sp_uint64 parentId = 0;
	id source = nil;
	
	if (isFolder) {
		NSDictionary *sourceFolderInfo = [NSKeyedUnarchiver unarchiveObjectWithData:folderSourceData];
		source = [sourceFolderInfo valueForKey:kFolderId];
		parentId = [[sourceFolderInfo valueForKey:kPlaylistParentId] unsignedLongLongValue];
	} else {
		NSDictionary *sourcePlaylistData = [NSKeyedUnarchiver unarchiveObjectWithData:playlistUrlData];
		source = [sourcePlaylistData valueForKey:kPlaylistURL];
		parentId = [[sourcePlaylistData valueForKey:kPlaylistParentId] unsignedLongLongValue];
	}
	
	dispatch_async([SPSession libSpotifyQueue], ^{
		
		id parent = parentId == 0 ? userPlaylists :
		[[SPSession sharedSession] playlistFolderForFolderId:parentId
												 inContainer:userPlaylists];
		
		NSInteger destinationIndex = index;
		if (item == nil) {
			destinationIndex = [self realIndexOfRootPlaylistAtIndexInOutlineView:index];
		}
		
		if (destinationIndex < 0)
			destinationIndex = 0;
		else if (destinationIndex > [[parent playlists] count])
			destinationIndex = [[parent playlists] count];
		
		NSInteger sourceIndex = [[parent playlists] indexOfObject:source];
		if (sourceIndex == destinationIndex)
			return;
		
		if (isFolder) {
			
			dispatch_async([SPSession libSpotifyQueue], ^{
				
				SPPlaylistFolder *folder = [[SPSession sharedSession] playlistFolderForFolderId:[(NSNumber *)source unsignedLongLongValue]
																					inContainer:userPlaylists];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					[userPlaylists moveItem:folder
									toIndex:destinationIndex
								ofNewParent:item
								   callback:^(NSError *error) {
									   if (error)
										   [self.sidebar.window.windowController presentError:error];
								   }];
				});
				
			});
			
		} else {
			
			[[SPSession sharedSession] playlistForURL:(NSURL *)source
											 callback:^(SPPlaylist *playlist) {
												 [userPlaylists moveItem:playlist
																 toIndex:destinationIndex
															 ofNewParent:item
																callback:^(NSError *error) {
																	if (error)
																		[self.sidebar.window.windowController presentError:error];
																}];
											 }];
			
		}

		
		
	});
		
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
	
	id item = [items objectAtIndex:0];
	
	if (![item isKindOfClass:[SPPlaylistFolder class]] && ![item isKindOfClass:[SPPlaylist class]])
		return NO;
	
	SPPlaylistFolder *parent = [outlineView parentForItem:item];
	
	if ([item isKindOfClass:[SPPlaylistFolder class]]) {
		
		NSMutableDictionary *repForReordering = [NSMutableDictionary dictionaryWithCapacity:2];
		[repForReordering setValue:[NSNumber numberWithUnsignedLongLong:[item folderId]]
							forKey:kFolderId];
		
		if (parent != nil)
			[repForReordering setValue:[NSNumber numberWithUnsignedLongLong:[parent folderId]]
								forKey:kPlaylistParentId];
		
		[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:repForReordering]
				forType:kSpotifyFolderMoveSourceDragIdentifier];
		
	} else {
		
		NSMutableDictionary *repForReordering = [NSMutableDictionary dictionaryWithCapacity:2];
		[repForReordering setValue:[item spotifyURL]
							forKey:kPlaylistURL];
		if (parent != nil)
			[repForReordering setValue:[NSNumber numberWithUnsignedLongLong:[parent folderId]]
								forKey:kPlaylistParentId];
		
		[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:repForReordering]
				forType:kSpotifyPlaylistMoveSourceDragIdentifier];
	}
	
	return YES;
}


@end
