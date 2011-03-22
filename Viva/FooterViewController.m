//
//  FooterViewController.m
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FooterViewController.h"

@implementation FooterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

@synthesize leftView;
@synthesize playbackControlsView;

-(void)awakeFromNib {
	
	((SPBackgroundColorView *)self.view).backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"bg"]];
	
	[self.view addSubview:self.leftView];
	[self.view addSubview:self.playbackControlsView];
	
}

#pragma mark -
#pragma mark SplitView

-(void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
	// Called when a splitview we care about has resized. 
	
	NSSplitView *splitView = [aNotification object];
	
	CGFloat dividerPosition = floorf([[[splitView subviews] objectAtIndex:0] frame].size.width + [splitView dividerThickness]);
	
	leftView.frame = (NSRect) {
		.origin = leftView.frame.origin,
		.size = NSMakeSize(dividerPosition, leftView.frame.size.height)
	};
	
	playbackControlsView.frame = (NSRect) {
		.origin = NSMakePoint(NSMaxX(leftView.frame), playbackControlsView.frame.origin.y),
		.size = CGSizeMake(NSWidth(self.view.bounds) - dividerPosition, playbackControlsView.frame.size.height)
	};
	
}

- (void)dealloc
{
    [super dealloc];
}

@end
