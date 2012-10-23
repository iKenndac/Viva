//
//  PlaylistsViewController.m
//  Viva
//
//  Created by Daniel Kennett on 23/08/2012.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "PlaylistsViewController.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaTrackInContainerReference.h"
#import "Constants.h"
#import "VivaAppDelegate.h"

@interface PlaylistsViewController ()

@end

@implementation PlaylistsViewController
@synthesize playlistTreeController;
@synthesize containerViewContainer;
@synthesize playlistsOutlineView;

-(id)initWithObjectFromURL:(NSURL *)aURL {
	self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
	if (self) {
		[self addObserver:self
			   forKeyPath:@"playlistTreeController.selection"
				  options:0
				  context:nil];
	}
	return self;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"playlistTreeController.selection"];
}

-(void)viewControllerDidActivateWithContext:(id)context {

}

-(void)displayItemAtURL:(NSURL *)url {
	NSViewController <VivaViewController> *vc = [[VivaInternalURLManager sharedInstance] viewControllerForURL:url];
	if (vc && vc != self)
		self.contentViewController = vc;

	[[SPSession sharedSession] objectRepresentationForSpotifyURL:url callback:^(sp_linktype linkType, id objectRepresentation) {
		/*[self.playlistsOutlineView selectRowIndexes:[NSIndexPath indexPathWithIndex:[self.playlistsOutlineView rowForItem:objectRepresentation]]
							   byExtendingSelection:NO];*/
	}];
}

-(void)awakeFromNib {
	[super awakeFromNib];
	self.leftColumnColorView.backgroundColor = [NSColor colorWithCalibratedRed:0.907 green:0.903 blue:0.887 alpha:1.000];
	self.backgroundColorView.backgroundColor = [NSColor whiteColor];

	[self.playlistsOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:kSpotifyTrackURLListDragIdentifier,
														kSpotifyPlaylistMoveSourceDragIdentifier,
														kSpotifyFolderMoveSourceDragIdentifier,
														nil]];

	self.playlistsOutlineView.target = self;
	self.playlistsOutlineView.doubleAction = @selector(outlineViewItemDoubleClicked:);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"playlistTreeController.selection"]) {
        id obj = [[self.playlistTreeController selectedObjects] lastObject];

		if ([obj isKindOfClass:[SPPlaylist class]]) {
			NSViewController <VivaViewController> *vc = [[VivaInternalURLManager sharedInstance] viewControllerForURL:[obj spotifyURL]];
			((VivaURLNavigationController *)[(MainWindowController *)self.view.window.windowController navigationController]).thePresent = [obj spotifyURL];
			self.contentViewController = vc;
		}


    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(SPSession *)session {
	return [SPSession sharedSession];
}

-(void)setContentViewController:(NSViewController<VivaViewController> *)contentViewController {

	if (self.contentViewController == contentViewController) return;

	if (self.contentViewController) {
		[self.containerViewContainer removeConstraints:self.containerViewContainer.constraints];
		[self setNextResponder:[self.contentViewController nextResponder]];
		[self.contentViewController setNextResponder:nil];
		[self.contentViewController.view removeFromSuperview];
	}

	_contentViewController = contentViewController;

	if (self.contentViewController) {
		
		[self.containerViewContainer addSubview:self.contentViewController.view];


		[self.containerViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[view(>=10)]-0-|"
																				options:NSLayoutAttributeBaseline | NSLayoutFormatDirectionLeadingToTrailing
																				metrics:nil
																				  views:@{@"view": self.contentViewController.view}]];

		[self.containerViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view(>=10)]-0-|"
																				options:NSLayoutAttributeBaseline | NSLayoutFormatDirectionLeadingToTrailing
																				metrics:nil
																				  views:@{@"view": self.contentViewController.view}]];

		NSResponder *responder = [self nextResponder];

		if (responder != self.containerViewContainer) {
			[self setNextResponder:self.containerViewContainer];
			[self.containerViewContainer setNextResponder:responder];
		}

	}

}

-(void)keyDown:(NSEvent *)theEvent {

	if ([theEvent keyCode] == 49) {
		[[NSApp delegate] performPlayPauseAction:nil];
	} else {
		[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
	}
}

-(void)moveLeft:(id)sender {
	[[NSApp delegate] performPreviousTrackAction:sender];
}

-(void)moveRight:(id)sender {
	[[NSApp delegate] performNextTrackAction:sender];
}

-(void)delete:(id)sender {

	if (self.view.window.firstResponder == self.playlistsOutlineView) {

		id playlist = [[self.playlistsOutlineView itemAtRow:self.playlistsOutlineView.selectedRow] representedObject];

		if (![playlist isKindOfClass:[SPPlaylist class]] && ![playlist isKindOfClass:[SPPlaylistFolder class]]) {
			NSBeep();
			return;
		}

		if (![playlist isKindOfClass:[SPPlaylistFolder class]] && [[playlist items] count] > 0) {

			[[NSAlert alertWithMessageText:@"Are you sure you want to delete this playlist?"
							 defaultButton:@"Delete"
						   alternateButton:@"Cancel"
							   otherButton:@""
				 informativeTextWithFormat:@"This operation cannot be undone, because I haven't written that code yet."]
			 beginSheetModalForWindow:[self.view window]
			 modalDelegate:self
			 didEndSelector:@selector(confirmPlaylistDeletionSheetDidEnd:returnCode:contextInfo:)
			 contextInfo:(__bridge void *)playlist];
		} else {
			[self confirmPlaylistDeletionSheetDidEnd:nil returnCode:NSAlertDefaultReturn contextInfo:(__bridge void *)playlist];
		}
	} else {
		NSBeep();
	}
}

-(void)confirmPlaylistDeletionSheetDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {

	if (returnCode == NSAlertDefaultReturn) {
		id playlist = (__bridge id)contextInfo;
		[[SPSession sharedSession].userPlaylists removeItem:playlist callback:nil];
	}
}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
	return YES;
}

-(IBAction)copySpotifyURI:(id)sender {

	NSTreeNode *item = nil;

	if (self.playlistsOutlineView.clickedRow != -1) {
		item = [self.playlistsOutlineView itemAtRow:self.playlistsOutlineView.clickedRow];
	} else if (self.playlistsOutlineView.selectedRowIndexes.count == 1) {
		item = [self.playlistsOutlineView itemAtRow:self.playlistsOutlineView.selectedRow];
	}

	id realItem = item.representedObject;

	if (realItem == nil || [realItem isKindOfClass:[SPPlaylistFolder class]]) {
		NSBeep();
		return;
	}

	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];

	[pasteboard declareTypes:[NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil] owner:nil];
	[pasteboard setString:[realItem spotifyURL].absoluteString forType:NSStringPboardType];
	[[realItem spotifyURL] writeToPasteboard:pasteboard];
}

-(void)outlineViewItemDoubleClicked:(id)sender {

	id item = [[self.playlistsOutlineView itemAtRow:self.playlistsOutlineView.clickedRow] representedObject];
    NSURL *url = [item spotifyURL];

    if (!url) return;
    id controller = [[VivaInternalURLManager sharedInstance] viewControllerForURL:url];

    if ([controller conformsToProtocol:@protocol(VivaPlaybackContext)]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTrackShouldBePlayedNotification
                                                            object:controller
                                                          userInfo:nil];
    }
}

#pragma mark - Drag & Drop

// What follows is likely the worst code you've ever seen. I'm *really* sorry. --Dan

-(SPPlaylistFolder *)folderWithId:(sp_uint64)folderId inArrayOfPlaylistsAndFolders:(NSArray *)stuff {

	for (id item in stuff) {
		if ([item isKindOfClass:[SPPlaylistFolder class]]) {
			SPPlaylistFolder *folder = (SPPlaylistFolder *)item;
			if (folder.folderId == folderId)
				return folder;
			SPPlaylistFolder *subFolder = [self folderWithId:folderId
								inArrayOfPlaylistsAndFolders:folder.playlists];
			if (subFolder)
				return subFolder;
		}
	}
	return nil;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView
				  validateDrop:(id < NSDraggingInfo >)info
				  proposedItem:(id)item
			proposedChildIndex:(NSInteger)index {

	NSData *trackUrlData = [[info draggingPasteboard] dataForType:kSpotifyTrackURLListDragIdentifier];

	if (trackUrlData != nil) {
		if ((![[item representedObject] isKindOfClass:[SPPlaylist class]]) ||
			([[item representedObject] isKindOfClass:[SPPlaylistFolder class]])) {
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
		sourceFolder = [self folderWithId:folderId inArrayOfPlaylistsAndFolders:userPlaylists.playlists];
		if (sourceFolder == nil) return NSDragOperationNone;
	}

	if (item == nil) {
		NSInteger indexOfFirstPlaylist = 0;
		NSInteger indexOfLastPlaylist = [SPSession sharedSession].userPlaylists.playlists.count - 1;

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
		 [[SPSession sharedSession].userPlaylists.playlists indexOfObject:item]];

		return NSDragOperationMove;
	}

	return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index {

	NSData *urlData = [[info draggingPasteboard] dataForType:kSpotifyTrackURLListDragIdentifier];

	if (urlData != nil) {

		dispatch_libspotify_async(^{

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
					if (error) [self.view.window presentError:error];
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

	dispatch_libspotify_async(^{

		id parent = parentId == 0 ? userPlaylists :
		[[SPSession sharedSession] playlistFolderForFolderId:parentId
												 inContainer:userPlaylists];

		NSInteger destinationIndex = index;

		if (destinationIndex < 0)
			destinationIndex = 0;
		else if (destinationIndex > [[parent playlists] count])
			destinationIndex = [[parent playlists] count];

		NSInteger sourceIndex = [[parent playlists] indexOfObject:source];
		if (sourceIndex == destinationIndex)
			return;

		if (isFolder) {

			dispatch_libspotify_async(^{

				SPPlaylistFolder *folder = [[SPSession sharedSession] playlistFolderForFolderId:[(NSNumber *)source unsignedLongLongValue]
																					inContainer:userPlaylists];

				dispatch_async(dispatch_get_main_queue(), ^{
					[userPlaylists moveItem:folder
									toIndex:destinationIndex
								ofNewParent:item
								   callback:^(NSError *error) {
									   if (error)
										   [self.view.window.windowController presentError:error];
								   }];
				});

			});

		} else {

			[[SPSession sharedSession] playlistForURL:(NSURL *)source
											 callback:^(SPPlaylist *playlist) {
												 [userPlaylists moveItem:playlist
																 toIndex:destinationIndex
															 ofNewParent:[item representedObject]
																callback:^(NSError *error) {
																	if (error)
																		[self.view.window presentError:error];
																}];
											 }];

		}



	});

	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {

	id item = [[items objectAtIndex:0] representedObject];

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

		[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:@{kItemReferenceURL : [item spotifyURL]}]
				forType:kSpotifyItemReferenceDragIdentifier];
	}

	return YES;
}

@end
