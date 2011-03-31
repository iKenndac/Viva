//
//  FooterViewController.h
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SPBackgroundColorView.h"
#import "VivaPlaybackManager.h"

@interface FooterViewController : NSViewController {
@private
    NSView *leftView;
	NSView *playbackControlsView;
	NSButton *trackIsStarredButton;
	NSButton *playbackIsRepeatingButton;
	NSButton *playbackIsShuffledButton;
	NSSlider *playbackProgressSlider;
    NSButton *playPauseButton;
	
	BOOL playbackRepeats;
	BOOL playbackIsShuffled;
    
    VivaPlaybackManager *playbackManager;
}

@property (assign) IBOutlet NSButton *trackIsStarredButton;
@property (assign) IBOutlet NSButton *playbackIsRepeatingButton;
@property (assign) IBOutlet NSButton *playbackIsShuffledButton;
@property (assign) IBOutlet NSSlider *playbackProgressSlider;
@property (assign) IBOutlet NSButton *playPauseButton;

@property (assign) IBOutlet NSView *leftView;
@property (assign) IBOutlet NSView *playbackControlsView;

- (IBAction)starredButtonWasClicked:(id)sender;
- (IBAction)repeatButtonWasClicked:(id)sender;
- (IBAction)shuffleButtonWasClicked:(id)sender;
- (IBAction)positionSliderWasDragged:(id)sender;
- (IBAction)playPausedWasClicked:(id)sender;

@property (retain, readwrite) VivaPlaybackManager *playbackManager;

@property (readwrite, nonatomic) BOOL playbackRepeats;
@property (readwrite, nonatomic) BOOL playbackIsShuffled;

@end
