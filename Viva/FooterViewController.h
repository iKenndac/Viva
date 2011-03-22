//
//  FooterViewController.h
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SPBackgroundColorView.h"

@interface FooterViewController : NSViewController {
@private
    NSView *leftView;
	NSView *playbackControlsView;
}

@property (assign) IBOutlet NSView *leftView;
@property (assign) IBOutlet NSView *playbackControlsView;



@end
