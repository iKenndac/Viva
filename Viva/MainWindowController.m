//
//  MainWindowController.m
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainWindowController.h"
#import <objc/objc-runtime.h>

@interface MainWindowController ()

@property (nonatomic, retain, readwrite) NSViewController *currentViewController;

@end

@implementation MainWindowController

@synthesize currentViewController;
@synthesize contentBox;
@synthesize playlistTreeController;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
	self.currentViewController = nil;
    [super dealloc];
}

-(void)awakeFromNib {
	[self windowDidLoad];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[self addObserver:self
		   forKeyPath:@"currentViewController"
			  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
			  context:nil];
	
	[self.playlistTreeController addObserver:self
								  forKeyPath:@"selection"
									 options:NSKeyValueObservingOptionInitial
									 context:nil];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selection"]) {
        
		id selectedObject = self.playlistTreeController.selectedObjects.lastObject;
		
		NSViewController *newViewController = objc_getAssociatedObject(selectedObject, "VivaViewController");
		
		if (newViewController == nil && [selectedObject respondsToSelector:@selector(createViewController)]) {
			newViewController = [selectedObject performSelector:@selector(createViewController)];
			objc_setAssociatedObject(selectedObject, "VivaViewController", newViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		}
		
		[self setCurrentViewController:newViewController];
		
	} else if ([keyPath isEqualToString:@"currentViewController"]) {
		
		NSViewController *newViewController = [change valueForKey:NSKeyValueChangeNewKey];
		
		if (newViewController != nil && newViewController != (id)[NSNull null]) {
			self.contentBox.contentView = newViewController.view;
		} else {
			self.contentBox.contentView = nil;
		}
		
		
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -
#pragma mark Split view

-(CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex {
	// Max size 
	return splitView.frame.size.width * 0.75;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
	// Min size
	return splitView.frame.size.width * 0.25;
}


@end
