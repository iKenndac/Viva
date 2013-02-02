//
//  VisualizerController.m
//  Viva
//
//  Created by Daniel Kennett on 02/02/2013.
//  Copyright (c) 2013 Spotify. All rights reserved.
//

#import "VisualizerController.h"

@interface VisualizerController ()

@property (strong, nonatomic, readwrite) iTunesPluginHost *pluginHost;
@property (strong, nonatomic, readwrite) iTunesVisualPlugin *runningVisualizer;
@property (strong, nonatomic, readwrite) NSWindow *visualizerWindow;

@end

@implementation VisualizerController

-(id)init {
	self = [super init];
	if (self) {
		self.pluginHost = [iTunesPluginHost new];
		self.activeVisualizer = [self.visualizers objectAtIndex:0];
		// ^ Todo: Remember the chosen visualiser
	}
	return self;
}

-(NSArray *)visualizers {
	return [[self.pluginHost plugins] valueForKeyPath:@"@unionOfArrays.visualizers"];
}

-(BOOL)visualizerVisible {
	return self.visualizerWindow.isVisible;
}

#pragma mark -

-(IBAction)ensureVisualizerVisible:(id)sender {

	if (self.activeVisualizer != self.runningVisualizer) {
		[self.runningVisualizer deactivate];
		self.runningVisualizer = nil;
	}

	self.runningVisualizer = self.activeVisualizer;

	[self createWindow];

	if (NSEqualSizes(self.runningVisualizer.maxSize, NSZeroSize))
		self.visualizerWindow.maxSize = NSMakeSize(FLT_MAX, FLT_MAX);
	else
		self.visualizerWindow.maxSize = self.runningVisualizer.maxSize;
	
	self.visualizerWindow.minSize = self.runningVisualizer.minSize;
	self.visualizerWindow.title = self.runningVisualizer.pluginName;

	[self.visualizerWindow makeKeyAndOrderFront:nil];
	[self.runningVisualizer activateInView:self.visualizerWindow.contentView];
}

-(void)createWindow {
	if (self.visualizerWindow != nil) return;

	self.visualizerWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0.0, 0.0, 640.0, 480.0)
														styleMask:NSResizableWindowMask | NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
														  backing:NSBackingStoreBuffered
															defer:NO];
	[self.visualizerWindow center];
	[self.visualizerWindow setReleasedWhenClosed:NO];
	self.visualizerWindow.delegate = self;
}

-(IBAction)hideVisualizer:(id)sender {
	[self.visualizerWindow close];
}

#pragma mark - Window Delegates

-(void)windowWillClose:(NSNotification *)notification {
	[self.runningVisualizer deactivate];
	self.runningVisualizer = nil;
}

-(void)windowDidResize:(NSNotification *)notification {
	[self.runningVisualizer containerViewFrameChanged];
}

-(void)windowDidMove:(NSNotification *)notification {
	[self.runningVisualizer containerViewFrameChanged];
}


@end
