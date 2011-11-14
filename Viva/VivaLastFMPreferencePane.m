//
//  VivaLastFMPreferencePane.m
//  Viva
//
//  Created by Daniel Kennett on 14/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import "VivaLastFMPreferencePane.h"
#import "LastFMController.h"

@interface VivaLastFMPreferencePane ()
@property (readwrite) BOOL isActive;
-(void)updateUI;
@end

@implementation VivaLastFMPreferencePane
@synthesize statusField;
@synthesize connectButton;

-(id)init {
	return [self initWithNibName:@"VivaLastFMPreferencePane" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
		
		[[LastFMController sharedInstance] addObserver:self
											forKeyPath:@"connectionState"
											   options:NSKeyValueObservingOptionInitial
											   context:nil];
		
    }
    
    return self;
}

-(void)dealloc {
	[[LastFMController sharedInstance] removeObserver:self forKeyPath:@"connectionState"];
}

@synthesize isActive;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"connectionState"]) {
        
		[self updateUI];
		
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (IBAction)connectOrDisconnectWithLastFM:(id)sender {
	
	if ([[LastFMController sharedInstance] connectionState] == kLastFMConnected)
		[[LastFMController sharedInstance] disconnectFromLastFM:sender];
	else
		[[LastFMController sharedInstance] connectWithLastFM:sender];
}

-(void)awakeFromNib {
	[self updateUI];
}

-(void)updateUI {
	self.isActive = ([[LastFMController sharedInstance] connectionState] == kLastFMWaitingForAuth);
	self.connectButton.enabled = !self.isActive;
	
	if ([[LastFMController sharedInstance] connectionState] == kLastFMDisconnected) {
		self.statusField.stringValue = @"Not Connected.";
		self.connectButton.title = @"Connect with Last.fm";
	} else if ([[LastFMController sharedInstance] connectionState] == kLastFMWaitingForAuth) {
		self.statusField.stringValue = @"Waiting for Authorization…";
	} else if ([[LastFMController sharedInstance] connectionState] == kLastFMConnected) {
		self.statusField.stringValue = [NSString stringWithFormat:@"Connected as %@.", [[LastFMController sharedInstance] loggedInUser]];
		self.connectButton.title = @"Disconnect from Last.fm";
	}
}


@end
