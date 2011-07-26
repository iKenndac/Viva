//
//  MainWindowSidebarController.h
//  Viva
//
//  Created by Daniel Kennett on 6/20/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const SPGroupTitleKey = @"SPGroupTitle";
static NSString * const SPGroupTitleIsShownKey = @"SPGroupTitleIsShown";
static NSString * const SPGroupIdentifierKey = @"SPGroupIdentifier";
static NSString * const SPGroupItemsKey = @"SPGroupItems";

static NSString * const SPItemTitleKey = @"SPItemTitle";
static NSString * const SPItemImageKeyKey = @"SPItemImageKey";
static NSString * const SPItemSpotifyURLKey = @"SPItemSpotifyURL";

static NSString * const SPItemUserPlaylistsPlaceholderTitle = @"SPUserPlaylistsPlaceholder";

static NSString * const SPSidebarTitleKey = @"title";
static NSString * const SPSidebarImageKey = @"image";
static NSString * const SPSidebarURLKey = @"url";

@interface MainWindowSidebarController : NSObject <NSOutlineViewDelegate, NSOutlineViewDataSource> {
	NSOutlineView *sidebar;
}


@property (readwrite, retain, nonatomic) NSTreeController *userPlaylistController;
@property (assign) IBOutlet NSOutlineView *sidebar;

@end
