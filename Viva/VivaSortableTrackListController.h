//
//  VivaSortableTrackListController.h
//  Viva
//
//  Created by Daniel Kennett on 4/22/11.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>
#import "VivaPlaybackContextViewController.h"

@interface VivaSortableTrackListController : VivaPlaybackContextViewController {
@private
	NSTableView *__weak trackTable;
	NSArrayController *__weak trackContainerArrayController;
	BOOL sortAscending;
	NSMutableArray *trackContainers;
}

@property (nonatomic, readwrite, strong) NSMutableArray *trackContainers;
@property (weak) IBOutlet NSArrayController *trackContainerArrayController;
@property (weak) IBOutlet NSTableView *trackTable;

@end
