//
//  VivaPreferencesWindowController.m
//  Viva
//
//  Created by Daniel Kennett on 14/11/2011.
//  For license information, see LICENSE.markdown
//

#import "VivaPreferencesWindowController.h"
#import "VivaGeneralPreferencePane.h"
#import "VivaLastFMPreferencePane.h"
#import "VivaLocalFilesPreferencePane.h"

@interface VivaPreferencesWindowController ()

@property (strong, nonatomic) VivaGeneralPreferencePane *generalPaneController;
@property (strong, nonatomic) VivaLastFMPreferencePane *lastFMPaneController;
@property (strong, nonatomic) VivaLocalFilesPreferencePane *localFilesController;

@property (strong, nonatomic) NSViewController *currentViewController;

-(void)switchToViewController:(NSViewController *)controller;

@end

@implementation VivaPreferencesWindowController

@synthesize generalButton;
@synthesize lastFMButton;
@synthesize localFilesButton;
@synthesize generalPaneController;
@synthesize lastFMPaneController;
@synthesize currentViewController;
@synthesize localFilesController;

-(void)awakeFromNib {
	
	[self.window center];
	
	self.localFilesButton.image = [[NSWorkspace sharedWorkspace] iconForFile:[[NSBundle mainBundle] resourcePath]];
	
	self.generalPaneController = [[VivaGeneralPreferencePane alloc] init];
	self.lastFMPaneController = [[VivaLastFMPreferencePane alloc] init];
	self.localFilesController = [[VivaLocalFilesPreferencePane alloc] init];
	
	[self switchToGeneralPane:self];
}

- (IBAction)switchToGeneralPane:(id)sender {
	[self switchToViewController:self.generalPaneController];
	[self.window.toolbar setSelectedItemIdentifier:self.generalButton.itemIdentifier];
}

- (IBAction)switchToLastFMPane:(id)sender {
	[self switchToViewController:self.lastFMPaneController];
	[self.window.toolbar setSelectedItemIdentifier:self.lastFMButton.itemIdentifier];
}

- (IBAction)switchToLocalFilesPane:(id)sender {
	[self switchToViewController:self.localFilesController];
	[self.window.toolbar setSelectedItemIdentifier:self.localFilesButton.itemIdentifier];
}

-(void)switchToViewController:(NSViewController *)controller {
	
	if (controller == self.currentViewController) return;
	
	[self.currentViewController.view removeFromSuperviewWithoutNeedingDisplay];
	
	self.currentViewController = controller;
	self.currentViewController.view.frame = ((NSView *)self.window.contentView).bounds;
	[self.window.contentView addSubview:self.currentViewController.view];
}

@end
