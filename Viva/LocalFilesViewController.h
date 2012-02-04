//
//  LocalFilesViewController.h
//  Viva
//
//  Created by Daniel Kennett on 04/02/2012.
//  For license information, see LICENSE.markdown
//
#import <Cocoa/Cocoa.h>
#import "VivaSortableTrackListController.h"

@interface LocalFilesViewController : VivaSortableTrackListController

@property (strong) IBOutlet NSArrayController *allTracksArrayController;

@end
