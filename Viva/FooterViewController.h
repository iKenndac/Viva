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
    NSView *__weak leftView;
	NSView *__weak playbackControlsView;
	NSButton *__weak trackIsStarredButton;
	NSButton *__weak playbackIsRepeatingButton;
	NSButton *__weak playbackIsShuffledButton;
	NSSlider *__weak playbackProgressSlider;
    NSButton *__weak playPauseButton;
    
    VivaPlaybackManager *playbackManager;
}

@property (weak) IBOutlet NSButton *trackIsStarredButton;
@property (weak) IBOutlet NSButton *playbackIsRepeatingButton;
@property (weak) IBOutlet NSButton *playbackIsShuffledButton;
@property (weak) IBOutlet NSSlider *playbackProgressSlider;
@property (weak) IBOutlet NSButton *playPauseButton;

@property (weak) IBOutlet NSView *leftView;
@property (weak) IBOutlet NSView *playbackControlsView;

@property (weak, readonly) NSString *currentTrackPositionDisplayString;
@property (weak, readonly) NSString *currentTrackDurationDisplayString;

- (IBAction)starredButtonWasClicked:(id)sender;
- (IBAction)repeatButtonWasClicked:(id)sender;
- (IBAction)shuffleButtonWasClicked:(id)sender;
- (IBAction)positionSliderWasDragged:(id)sender;
- (IBAction)playPauseButtonWasClicked:(id)sender;
- (IBAction)previousTrackButtonWasClicked:(id)sender;
- (IBAction)nextTrackButtonWasClicked:(id)sender;

@property (strong, readwrite) VivaPlaybackManager *playbackManager;

@end
