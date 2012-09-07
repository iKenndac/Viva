//
//  MainWindowController.h
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>
#import "FooterViewController.h"
#import "VivaURLNavigationController.h"
#import "LiveSearch.h"
#import "MainWindowSidebarController.h"
#import "SPBackgroundColorView.h"
#import "VivaInternalURLManager.h"

@interface MainWindowController : NSWindowController <NSSplitViewDelegate, VivaPlaybackManagerDataSource, NSPopoverDelegate, NSTextFieldDelegate>

@property (weak) IBOutlet NSSplitView *splitView;
@property (weak) IBOutlet SPBackgroundColorView *sourceListBackgroundColorView;
@property (weak) IBOutlet NSView *footerViewContainer;
@property (weak) IBOutlet MainWindowSidebarController *sidebarController;
@property (nonatomic, strong, readonly) NSViewController <VivaViewController> *currentViewController;
@property (nonatomic, strong, readonly) FooterViewController *footerViewController;
@property (nonatomic, strong, readonly) VivaURLNavigationController *navigationController;
@property (weak) IBOutlet NSOutlineView *sourceList;
@property (strong) IBOutlet NSPopover *searchPopover;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSView *contentView;

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
