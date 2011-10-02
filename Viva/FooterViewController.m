//
//  FooterViewController.m
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "FooterViewController.h"
#import "VivaPlaybackManager.h"
#import "Constants.h"

@interface FooterViewController ()

-(NSString *)displayStringForTimeInterval:(NSTimeInterval)anInterval;

@end

@implementation FooterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"FooterViewController" bundle:nibBundleOrNil];
    if (self) {
		// Force loading of the view right away, so we can do KVO properly. 
		[self view];
		
		[self addObserver:self 
			   forKeyPath:@"playbackManager.loopPlayback"
				  options:NSKeyValueObservingOptionInitial
				  context:nil];
	
		[self addObserver:self 
			   forKeyPath:@"playbackManager.shufflePlayback"
				  options:NSKeyValueObservingOptionInitial
				  context:nil];
		
		[self addObserver:self 
			   forKeyPath:@"playbackManager.currentTrackPosition"
				  options:0
				  context:nil];
        
        [self addObserver:self 
			   forKeyPath:@"playbackManager.playbackSession.playing"
				  options:0
				  context:nil];
        
        [self addObserver:self 
			   forKeyPath:@"playbackManager.currentTrack.starred"
				  options:0
				  context:nil];
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
	if ([keyPath isEqualToString:@"playbackManager.loopPlayback"]) {
        
		if (self.playbackManager.loopPlayback) {
			
			[playbackIsRepeatingButton setImage:[NSImage imageNamed:@"repeat-on"]];
			[playbackIsRepeatingButton setAlternateImage:[NSImage imageNamed:@"repeat-on-pushed"]];
		} else {
			[playbackIsRepeatingButton setImage:[NSImage imageNamed:@"repeat-off"]];
			[playbackIsRepeatingButton setAlternateImage:[NSImage imageNamed:@"repeat-off-pushed"]];
		}
	} else if ([keyPath isEqualToString:@"playbackManager.shufflePlayback"]) {
        
		if (self.playbackManager.shufflePlayback) {
			
			[playbackIsShuffledButton setImage:[NSImage imageNamed:@"shuffle-on"]];
			[playbackIsShuffledButton setAlternateImage:[NSImage imageNamed:@"shuffle-on-pushed"]];
		} else {
			[playbackIsShuffledButton setImage:[NSImage imageNamed:@"shuffle-off"]];
			[playbackIsShuffledButton setAlternateImage:[NSImage imageNamed:@"shuffle-off-pushed"]];
		}
		
	} else if ([keyPath isEqualToString:@"playbackManager.currentTrack.starred"]) {
        
		if (self.playbackManager.currentTrack.starred) {
			
			[trackIsStarredButton setImage:[NSImage imageNamed:@"starred"]];
			[trackIsStarredButton setAlternateImage:[NSImage imageNamed:@"starred-pushed"]];
		} else {
			[trackIsStarredButton setImage:[NSImage imageNamed:@"star"]];
			[trackIsStarredButton setAlternateImage:[NSImage imageNamed:@"star-pushed"]];
		}
		
	} else if ([keyPath isEqualToString:@"playbackManager.currentTrackPosition"]) {
		if (![[self.playbackProgressSlider cell] isHighlighted]) {
			[self.playbackProgressSlider setDoubleValue:[[self playbackManager] currentTrackPosition]];
		}
        
    } else if ([keyPath isEqualToString:@"playbackManager.playbackSession.playing"]) {

        if (((VivaPlaybackManager *)[self playbackManager]).playbackSession.playing) {
            [playPauseButton setImage:[NSImage imageNamed:@"pause"]];
            [playPauseButton setAlternateImage:[NSImage imageNamed:@"pause-pushed"]];
        } else {
            [playPauseButton setImage:[NSImage imageNamed:@"play"]];
            [playPauseButton setAlternateImage:[NSImage imageNamed:@"play-pushed"]];
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -

@synthesize trackIsStarredButton;
@synthesize playbackIsRepeatingButton;
@synthesize playbackIsShuffledButton;
@synthesize playbackProgressSlider;
@synthesize playPauseButton;
@synthesize leftView;
@synthesize playbackControlsView;

@synthesize playbackManager;

+(NSSet *)keyPathsForValuesAffectingCurrentTrackPositionDisplayString {
	return [NSSet setWithObjects:@"playbackManager.currentTrack", @"playbackManager.currentTrackPosition", nil];
}

-(NSString *)currentTrackPositionDisplayString {
	if (self.playbackManager.currentTrack != nil) {
		return [self displayStringForTimeInterval:self.playbackManager.currentTrackPosition];
	} else {
		return [self displayStringForTimeInterval:-1.0];
	}
}

+(NSSet *)keyPathsForValuesAffectingCurrentTrackDurationDisplayString {
	return [NSSet setWithObject:@"playbackManager.currentTrack"];
}

-(NSString *)currentTrackDurationDisplayString {
	if (self.playbackManager.currentTrack != nil) {
		return [self displayStringForTimeInterval:self.playbackManager.currentTrack.duration];
	} else {
		return [self displayStringForTimeInterval:-1.0];
	}
}

#pragma mark -

-(void)awakeFromNib {
	
	((SPBackgroundColorView *)self.view).backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"bg"]];
	
	[self.view addSubview:self.leftView];
	[self.view addSubview:self.playbackControlsView];	
}

- (IBAction)starredButtonWasClicked:(id)sender {
	self.playbackManager.currentTrack.starred = !self.playbackManager.currentTrack.starred;
}

- (IBAction)repeatButtonWasClicked:(id)sender {
	self.playbackManager.loopPlayback = !self.playbackManager.loopPlayback;
}

- (IBAction)shuffleButtonWasClicked:(id)sender {
	self.playbackManager.shufflePlayback = !self.playbackManager.shufflePlayback;
}

- (IBAction)positionSliderWasDragged:(id)sender {
	[[self playbackManager] seekToTrackPosition:[sender doubleValue]];
}

- (IBAction)playPauseButtonWasClicked:(id)sender {
    if (self.playbackManager.currentTrack == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTrackShouldBePlayedNotification
                                                            object:nil
                                                          userInfo:nil];
        
    } else {
        self.playbackManager.playbackSession.playing = !self.playbackManager.playbackSession.playing;
    }
}

- (IBAction)previousTrackButtonWasClicked:(id)sender {
	if (self.playbackManager.currentTrackPosition > kSkipBackThreshold) {
		[self.playbackManager seekToTrackPosition:0.0];
	} else {
		[self.playbackManager skipToPreviousTrackInCurrentContext:YES];
	}
}

- (IBAction)nextTrackButtonWasClicked:(id)sender {
	[self.playbackManager skipToNextTrackInCurrentContext:YES];
}

#pragma mark -

-(NSString *)displayStringForTimeInterval:(NSTimeInterval)anInterval {
	
	if (anInterval < 0.0) {
		return @"--:--";
	}
	
	BOOL hasHours = NO;
	
	if (anInterval > 3600.0) {
		hasHours = YES;
	}
	
	int hours = (int)floor(anInterval/3600);
	int minutes = (int)floor(anInterval/60) % 60;
	int seconds = (int)floor(anInterval) % 60;
	
	NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
	[formatter setFormat:@"00"];
	
	if (hasHours) {
		return [NSString stringWithFormat:@"%d:%@:%@", 
				hours, 
				[formatter stringFromNumber:[NSNumber numberWithInt:minutes]],
				[formatter stringFromNumber:[NSNumber numberWithInt:seconds]]];
	} else {
		return [NSString stringWithFormat:@"%d:%@", minutes, [formatter stringFromNumber:[NSNumber numberWithInt:seconds]]];
	}
	
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
	
    self.playbackManager = nil;
    
    [self removeObserver:self forKeyPath:@"playbackManager.currentTrack.starred"];
    [self removeObserver:self forKeyPath:@"playbackManager.playbackSession.playing"];
	[self removeObserver:self forKeyPath:@"playbackManager.currentTrackPosition"];
	[self removeObserver:self forKeyPath:@"playbackManager.shufflePlayback"];
	[self removeObserver:self forKeyPath:@"playbackManager.loopPlayback"];
	
    [super dealloc];
}


@end
