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

-(id)initWithObjectFromURL:(NSURL *)aURL {
	self = [super initWithObjectFromURL:aURL];
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
        [self rebuildTrackContainers];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(SPSession *)session {
	return [SPSession sharedSession];
}

-(void)rebuildTrackContainers {

	id selection = [self.playlistTreeController.selectedObjects lastObject];

	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[[selection items] count]];

	for (SPPlaylistItem *anItem in [selection items]) {

		if ([anItem.item isKindOfClass:[SPTrack class]])
			[newContainers addObject:[[VivaTrackInContainerReference alloc] initWithTrack:[anItem item]
																			  inContainer:selection]];
	}
	self.trackContainers = [NSMutableArray arrayWithArray:newContainers];
}

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
	NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), item);
	return YES;
}

@end
