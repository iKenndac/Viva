//
//  MainWindowController.h
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FooterViewController.h"

@interface MainWindowController : NSWindowController <NSSplitViewDelegate> {
@private
    
	NSView *footerViewContainer;
	FooterViewController *footerViewController;
	NSSplitView *splitView;
	NSBox *contentBox;
	NSTreeController *playlistTreeController;
	NSViewController *currentViewController;
	
	NSWindow *urlSheet;
	NSTextField *urlField;
	NSTextField *invalidURLWarningLabel;
}

@property (assign) IBOutlet NSSplitView *splitView;
@property (assign) IBOutlet NSView *footerViewContainer;
@property (assign) IBOutlet NSBox *contentBox;
@property (assign) IBOutlet NSTreeController *playlistTreeController;
@property (nonatomic, retain, readonly) NSViewController *currentViewController;
@property (nonatomic, retain, readonly) FooterViewController *footerViewController;

@property (assign) IBOutlet NSWindow *urlSheet;
@property (assign) IBOutlet NSTextField *urlField;
@property (assign) IBOutlet NSTextField *invalidURLWarningLabel;

- (IBAction)showOpenURLSheet:(id)sender;
- (IBAction)openURL:(id)sender;
- (IBAction)cancelOpenURL:(id)sender;

@end
