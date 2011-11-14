//
//  VivaPreferencesWindowController.m
//  Viva
//
//  Created by Daniel Kennett on 14/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import "VivaPreferencesWindowController.h"
#import "VivaGeneralPreferencePane.h"
#import "VivaLastFMPreferencePane.h"

@interface VivaPreferencesWindowController ()

@property (strong, nonatomic) VivaGeneralPreferencePane *generalPaneController;
@property (strong, nonatomic) VivaLastFMPreferencePane *lastFMPaneController;

@property (strong, nonatomic) NSViewController *currentViewController;

-(void)switchToViewController:(NSViewController *)controller;

@end

@implementation VivaPreferencesWindowController

@synthesize generalButton;
@synthesize lastFMButton;
@synthesize generalPaneController;
@synthesize lastFMPaneController;
@synthesize currentViewController;

-(void)awakeFromNib {
	
	[self.window center];
	
	self.generalPaneController = [[VivaGeneralPreferencePane alloc] init];
	self.lastFMPaneController = [[VivaLastFMPreferencePane alloc] init];
	
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

-(void)switchToViewController:(NSViewController *)controller {
	
	if (controller == self.currentViewController) return;
	
	[self.currentViewController.view removeFromSuperviewWithoutNeedingDisplay];
	
	self.currentViewController = controller;
	self.currentViewController.view.frame = ((NSView *)self.window.contentView).bounds;
	[self.window.contentView addSubview:self.currentViewController.view];
}

@end
