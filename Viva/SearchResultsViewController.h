//
//  SearchResultsViewController.h
//  Viva
//
//  Created by Daniel Kennett on 4/22/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VivaSortableTrackListController.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface SearchResultsViewController : VivaSortableTrackListController {
@private
	SPSpotifySearch *search;
}

@property (nonatomic, readonly, retain) SPSpotifySearch *search;

@end
