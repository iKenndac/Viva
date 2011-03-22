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
@property (nonatomic, retain, readwrite) FooterViewController *footerViewController;

@end

@implementation MainWindowController

@synthesize splitView;
@synthesize currentViewController;
@synthesize footerViewContainer;
@synthesize contentBox;
@synthesize playlistTreeController;
@synthesize footerViewController;

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
	self.footerViewController = nil;
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
    
	footerViewController = [[FooterViewController alloc] init];
	footerViewController.view.frame = self.footerViewContainer.bounds;
	[self.footerViewContainer addSubview:footerViewController.view];
	
	[[NSNotificationCenter defaultCenter] addObserver:footerViewController
											 selector:@selector(splitViewDidResizeSubviews:)
												 name:NSSplitViewDidResizeSubviewsNotification
											   object:self.splitView];
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
