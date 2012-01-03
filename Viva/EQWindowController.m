//
//  EQWindowController.m
//  Viva
//
//  Created by Daniel Kennett on 03/01/2012.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "EQWindowController.h"
#import "VivaPlaybackManager.h"
#import "VivaAppDelegate.h"

@implementation EQWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
		
		[self addObserver:self forKeyPath:@"band1" options:0 context:nil];
		[self addObserver:self forKeyPath:@"band2" options:0 context:nil];
		[self addObserver:self forKeyPath:@"band3" options:0 context:nil];
		[self addObserver:self forKeyPath:@"band4" options:0 context:nil];
		[self addObserver:self forKeyPath:@"band5" options:0 context:nil];
		[self addObserver:self forKeyPath:@"band6" options:0 context:nil];
		[self addObserver:self forKeyPath:@"band7" options:0 context:nil];
		[self addObserver:self forKeyPath:@"band8" options:0 context:nil];
		[self addObserver:self forKeyPath:@"band9" options:0 context:nil];
		[self addObserver:self forKeyPath:@"band10" options:0 context:nil];
		
    }
    
    return self;
}

-(void)awakeFromNib {
	[self.eqView addObserver:self forKeyPath:@"currentEQSettings" options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
	struct EQBands bands;
	
	if (object != self.eqView) {
		bands.band1 = self.band1;
		bands.band2 = self.band2;
		bands.band3 = self.band3;
		bands.band4 = self.band4;
		bands.band5 = self.band5;
		bands.band6 = self.band6;
		bands.band7 = self.band7;
		bands.band8 = self.band8;
		bands.band9 = self.band9;
		bands.band10 = self.band10;
		
		self.eqView.currentEQSettings = bands;
	} else {
		bands = self.eqView.currentEQSettings;
		[[(VivaAppDelegate *)[NSApp delegate] playbackManager] setEqBands:bands];
	}	
}

@synthesize band1;
@synthesize band2;
@synthesize band3;
@synthesize band4;
@synthesize band5;
@synthesize band6;
@synthesize band7;
@synthesize band8;
@synthesize band9;
@synthesize band10;
@synthesize eqView;

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
