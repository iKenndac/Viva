//
//  AlbumViewController.h
//  Viva
//
//  Created by Daniel Kennett on 4/24/11.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>
#import "VivaSortableTrackListController.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "SPBackgroundColorView.h"

@interface AlbumViewController : VivaSortableTrackListController {
@private
    SPAlbumBrowse *albumBrowse;
}

@property (weak) IBOutlet SPBackgroundColorView *backgroundColorView;

@property (nonatomic, readonly, strong) SPAlbumBrowse *albumBrowse;

@end
