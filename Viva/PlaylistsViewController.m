//
//  PlaylistsViewController.m
//  Viva
//
//  Created by Daniel Kennett on 23/08/2012.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "PlaylistsViewController.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaTrackInContainerReference.h"

@interface PlaylistsViewController ()

@end

@implementation PlaylistsViewController
@synthesize playlistTreeController;
@synthesize containerViewContainer;
@synthesize playlistsOutlineView;

-(id)initWithObjectFromURL:(NSURL *)aURL {
	self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
	if (self) {
		[self addObserver:self
			   forKeyPath:@"playlistTreeController.selection"
				  options:0
				  context:nil];
	}
	return self;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"playlistTreeController.selection"];
}

-(void)viewControllerDidActivateWithContext:(id)context {
	
}

-(void)awakeFromNib {
	[super awakeFromNib];
	self.leftColumnColorView.backgroundColor = [NSColor colorWithCalibratedRed:0.907 green:0.903 blue:0.887 alpha:1.000];
	self.backgroundColorView.backgroundColor = [NSColor whiteColor];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"playlistTreeController.selection"]) {
        id obj = [[self.playlistTreeController selectedObjects] lastObject];

		if ([obj isKindOfClass:[SPPlaylist class]]) {
			NSViewController <VivaViewController> *vc = [[VivaInternalURLManager sharedInstance] viewControllerForURL:[obj spotifyURL]];
			self.contentViewController = vc;
		}


    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(SPSession *)session {
	return [SPSession sharedSession];
}

-(void)setContentViewController:(NSViewController<VivaViewController> *)contentViewController {

	if (self.contentViewController) {
		[self setNextResponder:[self.contentViewController nextResponder]];
		[self.contentViewController setNextResponder:nil];
		[self.contentViewController.view removeFromSuperview];
	}

	_contentViewController = contentViewController;

	if (self.contentViewController) {
		
		[self.containerViewContainer addSubview:self.contentViewController.view];


		[self.containerViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[view(>=10)]-0-|"
																				options:NSLayoutAttributeBaseline | NSLayoutFormatDirectionLeadingToTrailing
																				metrics:nil
																				  views:@{@"view": self.contentViewController.view}]];

		[self.containerViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view(>=10)]-0-|"
																				options:NSLayoutAttributeBaseline | NSLayoutFormatDirectionLeadingToTrailing
																				metrics:nil
																				  views:@{@"view": self.contentViewController.view}]];

		NSResponder *responder = [self nextResponder];

		if (responder != self.containerViewContainer) {
			[self setNextResponder:self.containerViewContainer];
			[self.containerViewContainer setNextResponder:responder];
		}

	}

}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
	NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), item);
	return YES;
}

-(IBAction)copySpotifyURI:(id)sender {

	NSTreeNode *item = nil;

	if (self.playlistsOutlineView.clickedRow != -1) {
		item = [self.playlistsOutlineView itemAtRow:self.playlistsOutlineView.clickedRow];
	} else if (self.playlistsOutlineView.selectedRowIndexes.count == 1) {
		item = [self.playlistsOutlineView itemAtRow:self.playlistsOutlineView.selectedRow];
	}

	id realItem = item.representedObject;

	if (realItem == nil || [realItem isKindOfClass:[SPPlaylistFolder class]]) {
		NSBeep();
		return;
	}

	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];

	[pasteboard declareTypes:[NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil] owner:nil];
	[pasteboard setString:[realItem spotifyURL].absoluteString forType:NSStringPboardType];
	[[realItem spotifyURL] writeToPasteboard:pasteboard];
}

@end
