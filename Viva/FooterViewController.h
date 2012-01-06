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
#import "SPNowPlayingCoverView.h"
#import "VivaEQView.h"

@interface FooterViewController : NSViewController <VivaPlaybackManagerDelegate>

@property (weak) IBOutlet NSButton *trackIsStarredButton;
@property (weak) IBOutlet NSSlider *playbackProgressSlider;
@property (weak) IBOutlet NSButton *playPauseButton;
@property (weak) IBOutlet SPNowPlayingCoverView *coverView;
@property (strong) IBOutlet NSPopover *volumePopover;
@property (weak) IBOutlet NSSegmentedControl *playbackStateSegmentedControl;
@property (weak) IBOutlet NSTextField *titleField;
@property (weak) IBOutlet NSTextField *artistField;
@property (strong) IBOutlet NSPopover *errorPopover;
@property (weak) IBOutlet NSTextField *errorLabel;
@property (weak) IBOutlet VivaEQView *eqView;
@property (weak) IBOutlet NSPopUpButton *eqMenu;
@property (weak) IBOutlet NSTextField *eqNameField;
@property (strong) IBOutlet NSWindow *eqSaveWindow;

@property (weak, readonly) NSString *currentTrackPositionDisplayString;
@property (weak, readonly) NSString *currentTrackDurationDisplayString;

- (IBAction)starredButtonWasClicked:(id)sender;
- (IBAction)positionSliderWasDragged:(id)sender;
- (IBAction)playPauseButtonWasClicked:(id)sender;
- (IBAction)previousTrackButtonWasClicked:(id)sender;
- (IBAction)nextTrackButtonWasClicked:(id)sender;
- (IBAction)showVolumePopover:(id)sender;
- (IBAction)playbackStateControlWasClicked:(id)sender;

-(IBAction)chooseEqSetting:(id)sender;
- (IBAction)cancelEQSave:(id)sender;
- (IBAction)confirmEQSave:(id)sender;
-(IBAction)saveCurrentEQSettings:(id)sender;

@property (strong, readwrite) VivaPlaybackManager *playbackManager;

@end
