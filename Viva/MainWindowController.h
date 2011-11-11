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
#import "VivaInternalURLManager.h"

@interface MainWindowController : NSWindowController <NSSplitViewDelegate, VivaPlaybackManagerDataSource, NSPopoverDelegate, NSTextFieldDelegate> {
@private
    
	NSView *__weak footerViewContainer;
	FooterViewController *footerViewController;
	NSSplitView *__weak splitView;
	SPBackgroundColorView *__weak sourceListBackgroundColorView;
	NSBox *__weak contentBox;
	MainWindowSidebarController *__weak sidebarController;
	NSViewController <VivaViewController> *currentViewController;
	VivaURLNavigationController *navigationController;
	NSOutlineView *__weak sourceList;
	NSPopover *searchPopover;
	NSSearchField *__weak searchField;
	LiveSearch *liveSearch;
	
	NSWindow *__unsafe_unretained urlSheet;
	NSTextField *__weak urlField;
	NSTextField *__weak invalidURLWarningLabel;
}

@property (weak) IBOutlet NSSplitView *splitView;
@property (weak) IBOutlet SPBackgroundColorView *sourceListBackgroundColorView;
@property (weak) IBOutlet NSView *footerViewContainer;
@property (weak) IBOutlet NSBox *contentBox;
@property (weak) IBOutlet MainWindowSidebarController *sidebarController;
@property (nonatomic, strong, readonly) NSViewController <VivaViewController> *currentViewController;
@property (nonatomic, strong, readonly) FooterViewController *footerViewController;
@property (nonatomic, strong, readonly) VivaURLNavigationController *navigationController;
@property (weak) IBOutlet NSOutlineView *sourceList;
@property (strong) IBOutlet NSPopover *searchPopover;
@property (weak) IBOutlet NSSearchField *searchField;

@property (unsafe_unretained) IBOutlet NSWindow *urlSheet;
@property (weak) IBOutlet NSTextField *urlField;
@property (weak) IBOutlet NSTextField *invalidURLWarningLabel;

@property (readwrite, nonatomic, strong) LiveSearch *liveSearch;

-(void)navigateToURL:(NSURL *)aURL withContext:(id)context;

- (IBAction)showOpenURLSheet:(id)sender;
- (IBAction)openURL:(id)sender;
- (IBAction)cancelOpenURL:(id)sender;
- (IBAction)navigateForward:(id)sender;
- (IBAction)navigateBackward:(id)sender;
- (IBAction)performSearch:(id)sender;
- (IBAction)accountButtonClicked:(id)sender;

@end
