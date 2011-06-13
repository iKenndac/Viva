//
//  LiveSearchViewController.h
//  Viva
//
//  Created by Daniel Kennett on 6/9/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SPBackgroundImageView.h"

@interface LiveSearchViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource> {
	NSTableView *tableView;
	SPBackgroundImageView *gutterView;
	NSPopover *popover;
}

@property (assign) NSPopover *popover;
@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet SPBackgroundImageView *gutterView;

@end
