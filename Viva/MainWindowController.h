//
//  MainWindowController.h
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FooterViewController.h"
#import "VivaURLNavigationController.h"
#import "LiveSearch.h"
#import "MainWindowSidebarController.h"
#import "SPBackgroundColorView.h"

@interface MainWindowController : NSWindowController <NSSplitViewDelegate, NSPopoverDelegate, NSTextFieldDelegate> {
@private
    
	NSView *footerViewContainer;
	FooterViewController *footerViewController;
	NSSplitView *splitView;
	SPBackgroundColorView *sourceListBackgroundColorView;
	NSBox *contentBox;
	MainWindowSidebarController *sidebarController;
	NSViewController *currentViewController;
	VivaURLNavigationController *navigationController;
	NSOutlineView *sourceList;
	NSPopover *searchPopover;
	NSSearchField *searchField;
	LiveSearch *liveSearch;
	
	NSWindow *urlSheet;
	NSTextField *urlField;
	NSTextField *invalidURLWarningLabel;
}

@property (assign) IBOutlet NSSplitView *splitView;
@property (assign) IBOutlet SPBackgroundColorView *sourceListBackgroundColorView;
@property (assign) IBOutlet NSView *footerViewContainer;
@property (assign) IBOutlet NSBox *contentBox;
@property (assign) IBOutlet MainWindowSidebarController *sidebarController;
@property (nonatomic, retain, readonly) NSViewController *currentViewController;
@property (nonatomic, retain, readonly) FooterViewController *footerViewController;
@property (nonatomic, retain, readonly) VivaURLNavigationController *navigationController;
@property (assign) IBOutlet NSOutlineView *sourceList;
@property (assign) IBOutlet NSPopover *searchPopover;
@property (assign) IBOutlet NSSearchField *searchField;

@property (assign) IBOutlet NSWindow *urlSheet;
@property (assign) IBOutlet NSTextField *urlField;
@property (assign) IBOutlet NSTextField *invalidURLWarningLabel;

@property (readwrite, nonatomic, retain) LiveSearch *liveSearch;

- (IBAction)showOpenURLSheet:(id)sender;
- (IBAction)openURL:(id)sender;
- (IBAction)cancelOpenURL:(id)sender;
- (IBAction)navigateForward:(id)sender;
- (IBAction)navigateBackward:(id)sender;
- (IBAction)performSearch:(id)sender;
- (IBAction)accountButtonClicked:(id)sender;

@end
