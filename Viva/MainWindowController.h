//
//  MainWindowController.h
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MainWindowController : NSWindowController <NSSplitViewDelegate> {
@private
    
}

@property (assign) IBOutlet NSBox *contentBox;
@property (assign) IBOutlet NSTreeController *playlistTreeController;
@property (nonatomic, retain, readonly) NSViewController *currentViewController;

@end
