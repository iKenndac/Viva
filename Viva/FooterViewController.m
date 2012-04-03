//
//  FooterViewController.m
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  For license information, see LICENSE.markdown
//

#import "FooterViewController.h"
#import "VivaPlaybackManager.h"
#import "Constants.h"
#import "LastFMController.h"
#import "EQPresetController.h"

@interface FooterViewController ()

-(NSString *)displayStringForTimeInterval:(NSTimeInterval)anInterval;
-(NSMenuItem *)menuItemForPreset:(EQPreset *)preset;
-(NSMenu *)generateEqMenu;
-(void)resetEqUI;
-(void)ensureEqMenuSelectionMatchesCurrentEq;

@end

@implementation FooterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"FooterViewController" bundle:nibBundleOrNil];
    if (self) {
		// Force loading of the view right away, so we can do KVO properly. 
		[self view];
		
		[EQPresetController sharedInstance];
		
		[self addObserver:self 
			   forKeyPath:@"playbackManager.audioController.eqPreset" options:0
				  context:nil];
		
		[self addObserver:self
					  forKeyPath:@"eqView.currentEQSettings"
						 options:0
						 context:nil];
		
		[[EQPresetController sharedInstance] addObserver:self
											  forKeyPath:@"customPresets"
												 options:0
												 context:nil];
		
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
			   forKeyPath:@"playbackManager.playing"
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
    
	if ([keyPath isEqualToString:@"playbackManager.audioController.eqPreset"]) {
		
		[self removeObserver:self forKeyPath:@"eqView.currentEQSettings"];
		self.eqView.currentEQSettings = self.playbackManager.audioController.eqPreset;
		[self addObserver:self forKeyPath:@"eqView.currentEQSettings" options:0 context:nil];
		
		[self ensureEqMenuSelectionMatchesCurrentEq];
		
	} else if ([keyPath isEqualToString:@"eqView.currentEQSettings"]) {
		
		self.playbackManager.audioController.eqPreset = self.eqView.currentEQSettings;
		
	} else if ([keyPath isEqualToString:@"customPresets"]) {
		
		[self resetEqUI];
		[self ensureEqMenuSelectionMatchesCurrentEq];
	
	} else if ([keyPath isEqualToString:@"playbackManager.loopPlayback"]) {
			
		[self.playbackStateSegmentedControl setImage:[NSImage imageNamed:self.playbackManager.loopPlayback ? @"repeat-on" : @"repeat-off"]
											forSegment:0];

	} else if ([keyPath isEqualToString:@"playbackManager.shufflePlayback"]) {
        
		[self.playbackStateSegmentedControl setImage:[NSImage imageNamed:self.playbackManager.shufflePlayback ? @"shuffle-on" : @"shuffle-off"]
										  forSegment:1];
		
	} else if ([keyPath isEqualToString:@"playbackManager.currentTrack.starred"]) {
        
		if (self.playbackManager.currentTrack.starred) {
			
			[self.trackIsStarredButton setImage:[NSImage imageNamed:@"starred"]];
			[self.trackIsStarredButton setAlternateImage:[NSImage imageNamed:@"starred-pushed"]];
		} else {
			[self.trackIsStarredButton setImage:[NSImage imageNamed:@"star"]];
			[self.trackIsStarredButton setAlternateImage:[NSImage imageNamed:@"star-pushed"]];
		}
		
	} else if ([keyPath isEqualToString:@"playbackManager.currentTrackPosition"]) {
		if (![[self.playbackProgressSlider cell] isHighlighted]) {
			[self.playbackProgressSlider setDoubleValue:[[self playbackManager] currentTrackPosition]];
		}
        
    } else if ([keyPath isEqualToString:@"playbackManager.playing"]) {

        if (((VivaPlaybackManager *)[self playbackManager]).playing) {
            [self.playPauseButton setImage:[NSImage imageNamed:@"pause"]];
            [self.playPauseButton setAlternateImage:[NSImage imageNamed:@"pause-pushed"]];
        } else {
            [self.playPauseButton setImage:[NSImage imageNamed:@"play"]];
            [self.playPauseButton setAlternateImage:[NSImage imageNamed:@"play-pushed"]];
        }
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -

@synthesize trackIsStarredButton;
@synthesize playbackProgressSlider;
@synthesize playPauseButton;
@synthesize coverView;
@synthesize volumePopover;
@synthesize playbackStateSegmentedControl;
@synthesize titleField;
@synthesize artistField;
@synthesize errorPopover;
@synthesize errorLabel;
@synthesize eqView;
@synthesize eqMenu;
@synthesize eqNameField;
@synthesize eqSaveWindow;
@synthesize statsPopover;

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
	[self.coverView bind:@"image" toObject:self withKeyPath:@"playbackManager.currentTrack.album.cover.image" options:nil];

	[self.titleField setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
	[self.artistField setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
	
	[self resetEqUI];
}

- (IBAction)starredButtonWasClicked:(id)sender {
	self.playbackManager.currentTrack.starred = !self.playbackManager.currentTrack.starred;
	
	if (self.playbackManager.currentTrack.starred && [[NSUserDefaults standardUserDefaults] boolForKey:kStarEqualsLastFMLoveUserDefaultsKey])
		[[LastFMController sharedInstance] notifyLoveTrack:self.playbackManager.currentTrack];
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
        self.playbackManager.playing = !self.playbackManager.playing;
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

- (IBAction)showVolumePopover:(id)sender {
	NSView *aView = (NSView *)sender;
	[self.volumePopover showRelativeToRect:aView.bounds ofView:aView preferredEdge:NSMinYEdge];
}

- (IBAction)showStatsPopover:(id)sender {
	NSView *aView = (NSView *)sender;
	[self.statsPopover showRelativeToRect:aView.bounds ofView:aView preferredEdge:NSMinYEdge];
}

- (IBAction)playbackStateControlWasClicked:(id)sender {
	
	if (self.playbackStateSegmentedControl.selectedSegment == 0)
		self.playbackManager.loopPlayback = !self.playbackManager.loopPlayback;
	else
		self.playbackManager.shufflePlayback = !self.playbackManager.shufflePlayback;
	
}

#pragma mark -
#pragma mark Presets

-(IBAction)chooseEqSetting:(id)sender {
	
	if (self.eqMenu.selectedItem.representedObject == nil) {
		[self ensureEqMenuSelectionMatchesCurrentEq];
		return;
	}
	
	[self.eqView setCurrentEQSettings:self.eqMenu.selectedItem.representedObject animated:YES];
}

- (IBAction)cancelEQSave:(id)sender {
	[NSApp stopModal];
}

- (IBAction)confirmEQSave:(id)sender {
	
	if (self.eqNameField.stringValue.length == 0) {
		NSBeep();
		return;
	}
	
	EQPreset *existingPresetToReplace = nil;
	
	for (EQPreset *preset in [EQPresetController sharedInstance].customPresets) {
		if ([preset.name caseInsensitiveCompare:self.eqNameField.stringValue] == NSOrderedSame) {
			existingPresetToReplace = preset;
			break;
		}
	}
	
	if (existingPresetToReplace)
		[[EQPresetController sharedInstance] removeCustomPreset:existingPresetToReplace];
	
	EQPreset *newPreset = [self.eqView.currentEQSettings copy];
	newPreset.name = self.eqNameField.stringValue;
	
	[[EQPresetController sharedInstance] addCustomPreset:newPreset];
	self.eqView.currentEQSettings = newPreset;
	
	[self cancelEQSave:sender];
	
}

-(IBAction)saveCurrentEQSettings:(id)sender {
	self.eqNameField.stringValue = @"";
	[NSApp runModalForWindow:self.eqSaveWindow];
	[self.eqSaveWindow close];
	[self ensureEqMenuSelectionMatchesCurrentEq];
}

-(void)resetEqUI {
	self.eqMenu.menu = [self generateEqMenu];
	[self ensureEqMenuSelectionMatchesCurrentEq];
}

-(void)ensureEqMenuSelectionMatchesCurrentEq {
	
	for (NSMenuItem *item in self.eqMenu.menu.itemArray) {
		if (item.representedObject == self.eqView.currentEQSettings) {
			[self.eqMenu selectItem:item];
			break;
		}
	}
}

-(NSMenu *)generateEqMenu {
	
	EQPresetController *eqController = [EQPresetController sharedInstance];
	NSMenu *menu = [NSMenu new];
	
	[menu addItem:[self menuItemForPreset:eqController.blankPreset]];
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItem:[self menuItemForPreset:eqController.unnamedCustomPreset]];
	
	NSMenuItem *savePresetItem = [[NSMenuItem alloc] initWithTitle:@"Save…" action:@selector(saveCurrentEQSettings:) keyEquivalent:@""];
	savePresetItem.target = self;
	[menu addItem:savePresetItem];
		
	if (eqController.customPresets.count > 0) {
		[menu addItem:[NSMenuItem separatorItem]];
		
		for (EQPreset *preset in eqController.customPresets) {
			[menu addItem:[self menuItemForPreset:preset]];
		}
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
	for (EQPreset *preset in eqController.builtInPresets) {
		[menu addItem:[self menuItemForPreset:preset]];
	}
	
	return menu;
}

-(NSMenuItem *)menuItemForPreset:(EQPreset *)preset {
	
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:preset.name action:nil keyEquivalent:@""];
	[item setRepresentedObject:preset];
	return item;
}

#pragma mark -

-(void)playbackManager:(VivaPlaybackManager *)manager didEncounterPlaybackError:(NSError *)error {
	
	if (error.code == kVivaTrackTokenLostErrorCode) {
		self.errorLabel.stringValue = @"Playback was paused because your account was used for playback elsewhere.";
	} else if (error.code == kVivaTrackFailedToPlayErrorCode && [(SPTrack *)([[error.userInfo valueForKey:kVivaTrackContainerKey] track]) isLocal]) {
		self.errorLabel.stringValue = @"This local track is not in your library. Visit the Preferences to add it.";
	} else if (error.code == kVivaTrackFailedToPlayErrorCode) {
		self.errorLabel.stringValue = @"This track could not be played because it is not available in your area.";
	} else {
		self.errorLabel.stringValue = [NSString stringWithFormat:@"Playback failed with the following error: %@", error.localizedDescription];
	}
	
	[self.errorPopover showRelativeToRect:self.coverView.bounds ofView:self.coverView preferredEdge:NSMaxYEdge];
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
	
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
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

- (void)dealloc {
	
	[[EQPresetController sharedInstance] removeObserver:self forKeyPath:@"customPresets"];
    [self removeObserver:self forKeyPath:@"playbackManager.audioController.eqPreset"];
	[self removeObserver:self forKeyPath:@"eqView.currentEQSettings"];
    [self removeObserver:self forKeyPath:@"playbackManager.currentTrack.starred"];
    [self removeObserver:self forKeyPath:@"playbackManager.playing"];
	[self removeObserver:self forKeyPath:@"playbackManager.currentTrackPosition"];
	[self removeObserver:self forKeyPath:@"playbackManager.shufflePlayback"];
	[self removeObserver:self forKeyPath:@"playbackManager.loopPlayback"];
	
}


@end
