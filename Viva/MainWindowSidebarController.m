//
//  MainWindowSidebarController.m
//  Viva
//
//  Created by Daniel Kennett on 6/20/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "MainWindowSidebarController.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface MainWindowSidebarController ()

@property (readwrite, copy, nonatomic) NSArray *groups;

-(NSDictionary *)unifiedDictionaryForItem:(id)item;

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
    }
    
    return self;
}

@synthesize groups;
@synthesize userPlaylistController;

-(void)dealloc {
	self.groups = nil;
	[super dealloc];
}

-(NSDictionary *)unifiedDictionaryForItem:(id)item {
	
	if ([item isKindOfClass:[SPPlaylist class]]) {
		SPPlaylist *playlist = item;
		return [NSDictionary dictionaryWithObjectsAndKeys:
				playlist.name, SPSidebarTitleKey,
				[NSImage imageNamed:@"sidebar-playlist"], SPSidebarImageKey,
				playlist.spotifyURL, SPSidebarURLKey, 
				nil];
		
	} else if ([item isKindOfClass:[SPPlaylistFolder class]]) {
		SPPlaylistFolder *folder = item;
		return [NSDictionary dictionaryWithObjectsAndKeys:
				folder.name, SPSidebarTitleKey,
				[NSImage imageNamed:@"folder"], SPSidebarImageKey,
				nil];
		
	} else if ([item valueForKey:SPGroupIdentifierKey]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[item valueForKey:SPGroupTitleKey], SPSidebarTitleKey,
				nil];
		
	} else if ([item valueForKey:SPItemTitleKey]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[item valueForKey:SPItemTitleKey], SPSidebarTitleKey,
				[NSImage imageNamed:[item valueForKey:SPItemImageKeyKey]], SPSidebarImageKey,
				[item valueForKey:SPItemSpotifyURLKey], SPSidebarURLKey, 
				nil];
	}
	
	return nil;
}

#pragma mark -

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	
	if (item == nil) {
		// Root
		// We aren't treating groups as expandable items.
		
		NSInteger itemCount = 0;
		
		for (id group in self.groups) {
			if ([[group valueForKey:SPGroupTitleIsShownKey] boolValue])
				itemCount++;
			
			for (id item in [group valueForKey:SPGroupItemsKey]) {
				if ([[item valueForKey:SPItemTitleKey] isEqualToString:SPItemUserPlaylistsPlaceholderTitle])
					itemCount += ((NSArray *)(self.userPlaylistController.arrangedObjects)).count;
				else
					itemCount ++;
			}
		}
		return itemCount;
		
	}
	
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return NO;
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
	return [[item valueForKey:SPGroupTitleIsShownKey] boolValue];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	return [self unifiedDictionaryForItem:item];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	
	if (item == nil) {
		// Root
		// We aren't treating groups as expandable items.
		
		NSInteger currentIndex = 0;
		
		for (id group in self.groups) {
			
			if ([[group valueForKey:SPGroupTitleIsShownKey] boolValue] && currentIndex == index)
				return group;
			else if ([[group valueForKey:SPGroupTitleIsShownKey] boolValue])
				currentIndex++;
			
			for (id currentItem in [group valueForKey:SPGroupItemsKey]) {
				
				if ([[currentItem valueForKey:SPItemTitleKey] isEqualToString:SPItemUserPlaylistsPlaceholderTitle]){
					
					NSInteger playlistCount = ((NSArray *)(self.userPlaylistController.arrangedObjects)).count;
					NSInteger relativeIndex = index - currentIndex;
					
					if (relativeIndex < playlistCount && relativeIndex > 0)
						return [self.userPlaylistController.arrangedObjects objectAtIndex:relativeIndex];
					else
						currentIndex += playlistCount;
				} else if (currentIndex == index) {
					return currentItem;
				} else {
					currentIndex++;
				}
			}
		}
	}
	
	return nil;
}

@end
