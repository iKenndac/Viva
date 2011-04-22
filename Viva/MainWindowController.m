//
//  MainWindowController.m
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "MainWindowController.h"
#import "ImageAndTextCell.h"
#import "VivaInternalURLManager.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaAppDelegate.h"
#import "Constants.h"

@interface MainWindowController ()

@property (nonatomic, retain, readwrite) NSViewController *currentViewController;
@property (nonatomic, retain, readwrite) FooterViewController *footerViewController;
@property (nonatomic, retain, readwrite) VivaURLNavigationController *navigationController;

@end

@implementation MainWindowController

@synthesize urlSheet;
@synthesize urlField;
@synthesize invalidURLWarningLabel;
@synthesize splitView;
@synthesize currentViewController;
@synthesize footerViewContainer;
@synthesize contentBox;
@synthesize playlistTreeController;
@synthesize footerViewController;
@synthesize navigationController;
@synthesize sourceList;

-(id)init {
	return [super initWithWindowNibName:@"MainWindow"];
}

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"currentViewController"];
	[self.playlistTreeController removeObserver:self forKeyPath:@"selection.spotifyURL"];
	[self removeObserver:self forKeyPath:@"navigationController.thePresent"];
	
	self.navigationController = nil;
	self.currentViewController = nil;
	self.footerViewController = nil;
    [super dealloc];
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
	
	[self.playlistTreeController addObserver:self
								  forKeyPath:@"selection.spotifyURL"
									 options:0
									 context:nil];
	
	[self.sourceList registerForDraggedTypes:[NSArray arrayWithObject:kSpotifyTrackURLListDragIdentifier]];
    
	footerViewController = [[FooterViewController alloc] init];
	footerViewController.view.frame = self.footerViewContainer.bounds;
	footerViewController.playbackManager = [(VivaAppDelegate *)[NSApp delegate] playbackManager];
	[self.footerViewContainer addSubview:footerViewController.view];
	
	self.navigationController = [[[VivaURLNavigationController alloc] initWithUserDefaultsKey:kVivaMainViewHistoryUserDefaultsKey] autorelease];
	
	[[NSNotificationCenter defaultCenter] addObserver:footerViewController
											 selector:@selector(splitViewDidResizeSubviews:)
												 name:NSSplitViewDidResizeSubviewsNotification
											   object:self.splitView];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:NSSplitViewDidResizeSubviewsNotification object:self.splitView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selection.spotifyURL"]) {
		// Push the selected URL to the navigation controller.
		
		id selectedObject = self.playlistTreeController.selectedObjects.lastObject;
		
		if ([selectedObject respondsToSelector:@selector(spotifyURL)]) {
			NSURL *aURL = [selectedObject performSelector:@selector(spotifyURL) withObject:nil];
			if (aURL != nil) {
				self.navigationController.thePresent = aURL;
			}
		}
	
	} else if ([keyPath isEqualToString:@"navigationController.thePresent"]) {
		// Set the current view controller to the view controller for the current URL
		
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

- (IBAction)showOpenURLSheet:(id)sender {
	[self.urlField setStringValue:@""];
	[self.invalidURLWarningLabel setHidden:YES];
	
	[NSApp beginSheet:self.urlSheet
	   modalForWindow:self.window
		modalDelegate:nil
	   didEndSelector:nil 
		  contextInfo:nil];
}

- (IBAction)openURL:(id)sender {
	
	NSURL *aURL = [NSURL URLWithString:[self.urlField stringValue]];
	
	if (aURL == nil || [aURL spotifyLinkType] == SP_LINKTYPE_INVALID) {
		[self.invalidURLWarningLabel setHidden:NO];
		return;
	}
	
	self.navigationController.thePresent = aURL;
	
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
		NSURL *queryURL = [NSURL URLWithString:[NSString stringWithFormat:@"spotify:search:%@", [NSURL urlEncodedStringForString:searchQuery]]];
		self.navigationController.thePresent = queryURL;
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

#pragma mark -
#pragma mark Outline

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	
	[(ImageAndTextCell *)cell setImage:[[item representedObject] icon]];
	
} 

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView 
				  validateDrop:(id < NSDraggingInfo >)info 
				  proposedItem:(id)item 
			proposedChildIndex:(NSInteger)index {
	
	if ((![[item representedObject] isKindOfClass:[SPSpotifyPlaylist class]]) ||
		([[item representedObject] isKindOfClass:[SPSpotifyPlaylistFolder class]]))
		return NSDragOperationNone;
	
	NSData *urlData = [[info draggingPasteboard] dataForType:kSpotifyTrackURLListDragIdentifier];
	
	if (urlData != nil)
		return NSDragOperationCopy;
	else
		return NSDragOperationNone;
	
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index {
	
	NSData *urlData = [[info draggingPasteboard] dataForType:kSpotifyTrackURLListDragIdentifier];

	if (urlData == nil)
		return NO;
	
	NSArray *trackURLs = [NSKeyedUnarchiver unarchiveObjectWithData:urlData];
	NSMutableArray *tracksToAdd = [NSMutableArray arrayWithCapacity:[trackURLs count]];
	
	for (NSURL *url in trackURLs) {
		SPSpotifyTrack *track = nil;
		track = [SPSpotifyTrack trackForTrackURL:url inSession:[(VivaAppDelegate *)[NSApp delegate] session]];
		if (track != nil) {
			[tracksToAdd addObject:track];
		}
	}
	
	SPSpotifyPlaylist *targetPlaylist = [item representedObject];
	[targetPlaylist.tracks addObjectsFromArray:tracksToAdd];
	return YES;
	
}


@end
