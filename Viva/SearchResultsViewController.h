//
//  SearchResultsViewController.h
//  Viva
//
//  Created by Daniel Kennett on 4/22/11.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>
#import "VivaSortableTrackListController.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface SearchResultsViewController : VivaSortableTrackListController {
@private
	SPSearch *search;
}

@property (nonatomic, readonly, strong) SPSearch *search;

@end
