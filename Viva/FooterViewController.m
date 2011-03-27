//
//  FooterViewController.m
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "FooterViewController.h"

@implementation FooterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		// Force loading of the view right away, so we can do KVO properly. 
		[self view];
		
		[self addObserver:self 
			   forKeyPath:@"playbackRepeats"
				  options:NSKeyValueObservingOptionInitial
				  context:nil];
	
		[self addObserver:self 
			   forKeyPath:@"playbackIsShuffled"
				  options:NSKeyValueObservingOptionInitial
				  context:nil];
		
		[self addObserver:self 
			   forKeyPath:@"currentTrackIsStarred"
				  options:NSKeyValueObservingOptionInitial
				  context:nil];
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
	if ([keyPath isEqualToString:@"playbackRepeats"]) {
        
		if (self.playbackRepeats) {
			
			[playbackIsRepeatingButton setImage:[NSImage imageNamed:@"repeat-on"]];
			[playbackIsRepeatingButton setAlternateImage:[NSImage imageNamed:@"repeat-on-pushed"]];
		} else {
			[playbackIsRepeatingButton setImage:[NSImage imageNamed:@"repeat-off"]];
			[playbackIsRepeatingButton setAlternateImage:[NSImage imageNamed:@"repeat-off-pushed"]];
		}
	} else if ([keyPath isEqualToString:@"playbackIsShuffled"]) {
        
		if (self.playbackIsShuffled) {
			
			[playbackIsShuffledButton setImage:[NSImage imageNamed:@"shuffle-on"]];
			[playbackIsShuffledButton setAlternateImage:[NSImage imageNamed:@"shuffle-on-pushed"]];
		} else {
			[playbackIsShuffledButton setImage:[NSImage imageNamed:@"shuffle-off"]];
			[playbackIsShuffledButton setAlternateImage:[NSImage imageNamed:@"shuffle-off-pushed"]];
		}
		
	} else if ([keyPath isEqualToString:@"currentTrackIsStarred"]) {
        
		if (self.currentTrackIsStarred) {
			
			[trackIsStarredButton setImage:[NSImage imageNamed:@"starred"]];
			[trackIsStarredButton setAlternateImage:[NSImage imageNamed:@"starred-pushed"]];
		} else {
			[trackIsStarredButton setImage:[NSImage imageNamed:@"star"]];
			[trackIsStarredButton setAlternateImage:[NSImage imageNamed:@"star-pushed"]];
		}
		
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@synthesize trackIsStarredButton;
@synthesize playbackIsRepeatingButton;
@synthesize playbackIsShuffledButton;
@synthesize leftView;
@synthesize playbackControlsView;

@synthesize playbackRepeats;
@synthesize playbackIsShuffled;
@synthesize currentTrackIsStarred;

-(void)awakeFromNib {
	
	((SPBackgroundColorView *)self.view).backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"bg"]];
	
	[self.view addSubview:self.leftView];
	[self.view addSubview:self.playbackControlsView];
	
}

- (IBAction)starredButtonWasClicked:(id)sender {
	self.currentTrackIsStarred = !self.currentTrackIsStarred;
}

- (IBAction)repeatButtonWasClicked:(id)sender {
	self.playbackRepeats = !self.playbackRepeats;
}

- (IBAction)shuffleButtonWasClicked:(id)sender {
	self.playbackIsShuffled = !self.playbackIsShuffled;
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
		.size = NSMakeSize(NSWidth(self.view.bounds) - dividerPosition, playbackControlsView.frame.size.height)
	};
	
}

#pragma mark -

- (void)dealloc {
	
	[self removeObserver:self forKeyPath:@"playbackIsShuffled"];
	[self removeObserver:self forKeyPath:@"playbackRepeats"];
	[self removeObserver:self forKeyPath:@"currentTrackIsStarred"];
	
    [super dealloc];
}


@end
