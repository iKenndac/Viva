//
//  MainWindowController.m
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  For license information, see LICENSE.markdown
//

#import "MainWindowController.h"
#import "ImageAndTextCell.h"
#import "VivaInternalURLManager.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaAppDelegate.h"
#import "LiveSearchViewController.h"
#import "Constants.h"

static NSString * const kVivaWindowControllerLiveSearchObservationContext = @"kVivaWindowControllerLiveSearchObservationContext";

@interface MainWindowController ()

@property (nonatomic, strong, readwrite) NSViewController <VivaViewController> *currentViewController;
@property (nonatomic, strong, readwrite) FooterViewController *footerViewController;
@property (nonatomic, strong, readwrite) VivaURLNavigationController *navigationController;

-(void)confirmPlaylistDeletionSheetDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

@end

@implementation MainWindowController

@synthesize urlSheet;
@synthesize urlField;
@synthesize invalidURLWarningLabel;
@synthesize splitView;
@synthesize sourceListBackgroundColorView;
@synthesize currentViewController;
@synthesize footerViewContainer;
@synthesize contentBox;
@synthesize sidebarController;
@synthesize footerViewController;
@synthesize navigationController;
@synthesize sourceList;
@synthesize searchPopover;
@synthesize searchField;
@synthesize liveSearch;

-(id)init {
	return [super initWithWindowNibName:@"MainWindow"];
}

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"currentViewController"];
	[self removeObserver:self forKeyPath:@"liveSearch.latestSearch.searchInProgress"];
	[self.sidebarController removeObserver:self forKeyPath:@"selectedURL"];
	[self removeObserver:self forKeyPath:@"navigationController.thePresent"];
	
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[self addObserver:self
		   forKeyPath:@"currentViewController"
			  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
			  context:nil];
	
	[self addObserver:self
		   forKeyPath:@"navigationController.thePresent"
			  options:0
			  context:nil];
	
	[self addObserver:self
		   forKeyPath:@"liveSearch.latestSearch.searchInProgress"
			  options:0
			  context:(__bridge void *)kVivaWindowControllerLiveSearchObservationContext];
	
	[self.sidebarController addObserver:self
							 forKeyPath:@"selectedURL"
								options:0
								context:nil];
	
	self.sourceListBackgroundColorView.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"AwesomeKindaTileableTextureForVivaWhichIsAwesomeAsWell"]];
	
	[self.sourceList registerForDraggedTypes:[NSArray arrayWithObjects:kSpotifyTrackURLListDragIdentifier,
											  kSpotifyPlaylistMoveSourceDragIdentifier, 
											  kSpotifyFolderMoveSourceDragIdentifier,
											  nil]];
    
	footerViewController = [[FooterViewController alloc] init];
	footerViewController.view.frame = self.footerViewContainer.bounds;
	footerViewController.playbackManager = [(VivaAppDelegate *)[NSApp delegate] playbackManager];
	footerViewController.playbackManager.delegate = footerViewController;
	[self.footerViewContainer addSubview:footerViewController.view];
	
	self.navigationController = [[VivaURLNavigationController alloc] initWithUserDefaultsKey:kVivaMainViewHistoryUserDefaultsKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
   
	if (context == (__bridge void *)kVivaWindowControllerLiveSearchObservationContext) {
		if (!self.liveSearch.latestSearch.searchInProgress && !self.searchPopover.isShown && self.searchField.stringValue.length > 0) {
			
            self.searchPopover = [[NSPopover alloc] init];
            
			NSText *editor = [self.window fieldEditor:YES forObject:self.searchField];
			NSRange selection = editor.selectedRange;
			
			LiveSearchViewController *ls = [[LiveSearchViewController alloc] init];
			ls.popover = self.searchPopover;
			
			self.searchPopover.contentViewController = ls;
			self.searchPopover.contentViewController.representedObject = self.liveSearch;
			self.searchPopover.contentSize = NSMakeSize(self.searchField.frame.size.width, 300.0);
			[self.searchPopover showRelativeToRect:[self.searchField frame] ofView:self.searchField preferredEdge:NSMaxYEdge];
			[self.searchField becomeFirstResponder];
			
			editor.selectedRange = selection;
		}
			
	} else if ([keyPath isEqualToString:@"selectedURL"]) {
		// Push the selected URL to the navigation controller.
		
		if (self.sidebarController.selectedURL != nil)
			self.navigationController.thePresent = self.sidebarController.selectedURL;

	} else if ([keyPath isEqualToString:@"navigationController.thePresent"]) {
		// Set the current view controller to the view controller for the current URL
		
		if (![self.navigationController.thePresent isEqual:self.sidebarController.selectedURL])
			self.sidebarController.selectedURL = self.navigationController.thePresent;
		
		[self setCurrentViewController:[[VivaInternalURLManager sharedInstance] viewControllerForURL:self.navigationController.thePresent]];
		
	} else if ([keyPath isEqualToString:@"currentViewController"]) {
		// Display the view controller
		
		NSViewController *oldViewController = [change valueForKey:NSKeyValueChangeOldKey];
		NSViewController *newViewController = [change valueForKey:NSKeyValueChangeNewKey];
		
		if (oldViewController != (id)[NSNull null]) {
			[[self window] setNextResponder:[oldViewController nextResponder]];
			[oldViewController setNextResponder:nil];
		}
		
		if (newViewController != nil && newViewController != (id)[NSNull null]) {
			self.contentBox.contentView = newViewController.view;
			
			NSResponder *responder = [[self window] nextResponder];
			
			if (responder != newViewController) {
				[[self window] setNextResponder:newViewController];
				[newViewController setNextResponder:responder];
			}

		} else {
			self.contentBox.contentView = nil;
		}
		
		
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(IBAction)logOut:(id)sender {
	[[NSApp delegate] logOut];
}

- (IBAction)showOpenURLSheet:(id)sender {
	[self.invalidURLWarningLabel setHidden:YES];
	
	[NSApp beginSheet:self.urlSheet
	   modalForWindow:self.window
		modalDelegate:nil
	   didEndSelector:nil 
		  contextInfo:nil];
}

- (IBAction)openURL:(id)sender {
	
	NSURL *aURL = [NSURL URLWithString:[self.urlField stringValue]];
	
	if (aURL == nil) {
		[self.invalidURLWarningLabel setHidden:NO];
		return;
	}
	
	[[NSApp delegate] handleURL:aURL];
	
	[self cancelOpenURL:nil];
}

- (IBAction)cancelOpenURL:(id)sender {
	[NSApp endSheet:self.urlSheet];
	[self.urlSheet orderOut:sender];
}

- (IBAction)navigateForward:(id)sender {
	if ([self.navigationController.theFuture count] > 0) {
		self.navigationController.thePresent = [self.navigationController.theFuture objectAtIndex:0];
	} else {
		NSBeep();
	}
}

- (IBAction)navigateBackward:(id)sender {
	if ([self.navigationController.thePast count] > 0) {
		self.navigationController.thePresent = [self.navigationController.thePast lastObject];
	} else {
		NSBeep();
	}
}

- (IBAction)performSearch:(id)sender {
	
	NSString *searchQuery = [sender stringValue];
	
	if ([searchQuery length] > 0) {
		[self.searchPopover close];
        self.searchPopover = nil;
		NSURL *queryURL = [NSURL URLWithString:[NSString stringWithFormat:@"spotify:search:%@", [NSURL urlEncodedStringForString:searchQuery]]];
		self.navigationController.thePresent = queryURL;
	}
}

- (IBAction)accountButtonClicked:(id)sender {
}

#pragma mark -

-(void)navigateToURL:(NSURL *)aURL withContext:(id)context {
	
	if ([[VivaInternalURLManager sharedInstance] canHandleURL:aURL]) {
		self.navigationController.thePresent = aURL;
		[self.currentViewController viewControllerDidActivateWithContext:context];
	}
}

#pragma mark -

-(void)keyDown:(NSEvent *)theEvent {
	
	if ([theEvent keyCode] == 49) {
		[[NSApp delegate] performPlayPauseAction:nil];
	} else {
		[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
	}
}

-(void)moveLeft:(id)sender {
	[[NSApp delegate] performPreviousTrackAction:sender];
}

-(void)moveRight:(id)sender {
	[[NSApp delegate] performNextTrackAction:sender];
}

-(void)delete:(id)sender {
	
	if (self.window.firstResponder == self.sourceList) {
		
		id playlist = [self.sourceList itemAtRow:self.sourceList.selectedRow];
		
		if (![playlist isKindOfClass:[SPPlaylist class]] && ![playlist isKindOfClass:[SPPlaylistFolder class]]) {
			NSBeep();
			return;
		}
		
		if (![playlist isKindOfClass:[SPPlaylistFolder class]] && [[playlist items] count] > 0) {
			
			[[NSAlert alertWithMessageText:@"Are you sure you want to delete this playlist?"
							 defaultButton:@"Delete"
						   alternateButton:@"Cancel"
							   otherButton:@""
				 informativeTextWithFormat:@"This operation cannot be undone, because I haven't written that code yet."]
			 beginSheetModalForWindow:[self window]
			 modalDelegate:self
			 didEndSelector:@selector(confirmPlaylistDeletionSheetDidEnd:returnCode:contextInfo:)
			 contextInfo:(__bridge void *)playlist];
		} else {
			[self confirmPlaylistDeletionSheetDidEnd:nil returnCode:NSAlertDefaultReturn contextInfo:(__bridge void *)playlist];
		}
	} else {
		NSBeep();
	}
}

-(void)confirmPlaylistDeletionSheetDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	
	if (returnCode == NSAlertDefaultReturn) {
		id playlist = (__bridge id)contextInfo;
		[[SPSession sharedSession].userPlaylists removeItem:playlist callback:nil];
	}
}

#pragma mark -
#pragma mark Playlists

-(IBAction)newPlaylist:(id)sender {
	[[[SPSession sharedSession] userPlaylists] createPlaylistWithName:@"New Playlist" callback:nil];
}

-(IBAction)newPlaylistFolder:(id)sender {
	[[[SPSession sharedSession] userPlaylists] createFolderWithName:@"New Folder"
														   callback:^(SPPlaylistFolder *folder, NSError *error) {
															   if (error) {
																   [self presentError:error];
															   }
														   }];
	
}

#pragma mark -
#pragma mark Playback

-(BOOL)playbackManager:(VivaPlaybackManager *)manager requiresContextForContextlessPlayRequest:(id <VivaPlaybackContext> *)context {

    if (context == NULL)
        return NO;
    
    NSURL *url = self.navigationController.thePresent;
    id controller = [[VivaInternalURLManager sharedInstance] viewControllerForURL:url];
    
    if (![controller conformsToProtocol:@protocol(VivaPlaybackContext)])
        return NO;

    *context = controller;
    return YES;
}

#pragma mark -
#pragma mark Live Search

-(void)controlTextDidChange:(NSNotification *)obj {
	
	if (self.searchField.stringValue.length == 0 && self.searchPopover.isShown) {
		[self.searchPopover close];
        self.searchPopover = nil;
		self.liveSearch = nil;
	}
	
	[self performSelector:@selector(applyCurrentSearchQueryToLiveSearch)
			   withObject:nil
			   afterDelay:kLiveSearchChangeInterval];
	
}

-(void)applyCurrentSearchQueryToLiveSearch {
	
	[NSThread cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
	
	NSString *searchQuery = self.searchField.stringValue;
	
	if ([searchQuery isEqualToString:self.liveSearch.latestSearch.searchQuery] || [searchQuery length] == 0)
		return;
	
	SPSearch *newSearch = [SPSearch liveSearchWithSearchQuery:searchQuery
													inSession:[SPSession sharedSession]];
	
	if (self.liveSearch == nil) {
		self.liveSearch = [[LiveSearch alloc] initWithInitialSearch:newSearch];
	} else {
		self.liveSearch.latestSearch = newSearch;
	}
}

#pragma mark -
#pragma mark Split view

-(CGFloat)splitView:(NSSplitView *)aSplitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex {
	// Max size 
	return aSplitView.frame.size.width * 0.75;
}

- (CGFloat)splitView:(NSSplitView *)aSplitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
	// Min size
	return aSplitView.frame.size.width * 0.25;
}

- (void)splitView:(NSSplitView *)aSplitView resizeSubviewsWithOldSize:(NSSize)oldSize {
    
    NSInteger leftColumnWidth = 0.0;
    NSInteger effectiveDividerWidth = 0.0;
    
    NSView *leftColumnView = [[aSplitView subviews] objectAtIndex:0];
	
	NSUInteger kMaximumUserListWidth = aSplitView.frame.size.width * 0.75;
    NSUInteger kMinimumUserListWidth = aSplitView.frame.size.width * 0.25;
	
    if (![leftColumnView isHidden]) {
        if ([leftColumnView frame].size.width > kMaximumUserListWidth) {
            NSRect frame = [leftColumnView frame];
            frame.size.width = kMaximumUserListWidth;
            [leftColumnView setFrame:frame];
        }
        
        if ([leftColumnView frame].size.width < kMinimumUserListWidth) {
            NSRect frame = [leftColumnView frame];
            frame.size.width = kMinimumUserListWidth;
            [leftColumnView setFrame:frame];
        }
        
        leftColumnWidth = [leftColumnView frame].size.width;
        effectiveDividerWidth = [aSplitView dividerThickness];
    }
	
	NSView *contentView = [[aSplitView subviews] objectAtIndex:1];
	
    NSRect frame = [contentView frame];
    frame.origin.x = effectiveDividerWidth + leftColumnWidth;
    frame.size.width = [aSplitView frame].size.width - effectiveDividerWidth - leftColumnWidth;
    frame.size.height = [aSplitView frame].size.height; 
    
    [contentView setFrame:frame];
    
    if (![leftColumnView isHidden]) {
        [[[aSplitView subviews] objectAtIndex:0] setFrameSize:NSMakeSize(leftColumnWidth, frame.size.height)];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSSplitViewDidResizeSubviewsNotification
                                                        object:aSplitView
                                                      userInfo:nil];
}

@end
