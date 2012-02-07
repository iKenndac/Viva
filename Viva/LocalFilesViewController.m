//
//  LocalFilesViewController.m
//  Viva
//
//  Created by Daniel Kennett on 04/02/2012.
//  For license information, see LICENSE.markdown
//

#import "LocalFilesViewController.h"
#import "LocalFilesController.h"
#import "VivaTrackInContainerReference.h"

static void * const kLocalFilesViewControllerInternalKVOContext = @"blah";

@interface LocalFilesViewController ()

-(void)rebuildTrackContainers;

@end

@implementation LocalFilesViewController

@synthesize allTracksArrayController;

-(id)initWithObjectFromURL:(NSURL *)aURL {
	return [self initWithObjectFromURL:aURL nibName:@"LocalFilesViewController"];
}

-(id)initWithObjectFromURL:(NSURL *)aURL nibName:(NSString *)nibName {
	
	if (self = [super initWithObjectFromURL:aURL nibName:nibName]) {
		[self addObserver:self
			   forKeyPath:@"allTracksArrayController.arrangedObjects"
				  options:0
				  context:kLocalFilesViewControllerInternalKVOContext];

	}
	return self;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"allTracksArrayController.arrangedObjects"];
}

-(void)awakeFromNib {
	[super awakeFromNib];
	[(id)self tableView:self.trackTable didClickTableColumn:[self.trackTable tableColumnWithIdentifier:@"artist"]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == kLocalFilesViewControllerInternalKVOContext) {
        [self rebuildTrackContainers];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(LocalFilesController *)localFilesController {
	return [LocalFilesController sharedInstance];
}

-(void)rebuildTrackContainers {
	
	NSMutableArray *newContainers = [NSMutableArray arrayWithCapacity:[self.allTracksArrayController.arrangedObjects count]];
	
	for (SPTrack *anItem in self.allTracksArrayController.arrangedObjects) {
		[newContainers addObject:[[VivaTrackInContainerReference alloc] initWithTrack:anItem inContainer:nil]];
	}
	self.trackContainers = [NSMutableArray arrayWithArray:newContainers];
}

@end
