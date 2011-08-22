//
//  VisualiserWindowController.m
//  Viva
//
//  Created by Daniel Kennett on 8/22/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VisualiserWindowController.h"

@implementation VisualiserWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
	}
    
    return self;
}

@synthesize leftValue1;
@synthesize leftValue2;
@synthesize leftValue3;
@synthesize leftValue4;
@synthesize leftValue5;
@synthesize leftValue6;
@synthesize leftValue7;
@synthesize leftValue8;
@synthesize leftValue9;
@synthesize leftValue10;

@synthesize rightValue1;
@synthesize rightValue2;
@synthesize rightValue3;
@synthesize rightValue4;
@synthesize rightValue5;
@synthesize rightValue6;
@synthesize rightValue7;
@synthesize rightValue8;
@synthesize rightValue9;
@synthesize rightValue10;

- (void)windowDidLoad
{
    [super windowDidLoad];
	
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void)awakeFromNib {
	
	NSRect existingContentFrame = ((NSView *)self.window.contentView).frame;
	CGFloat temp = existingContentFrame.size.width;
	existingContentFrame.size.width = existingContentFrame.size.height;
	existingContentFrame.size.height = temp;
	[self.window setFrame:[self.window frameRectForContentRect:existingContentFrame] display:YES];
	
	[self.window.contentView setFrame:NSMakeRect(existingContentFrame.size.height, 0.0, existingContentFrame.size.height, existingContentFrame.size.width)];
	[self.window.contentView setFrameOrigin:NSMakePoint(((NSView *)self.window.contentView).frame.size.height, 0.0)];
	[self.window.contentView setFrameRotation:90.0];
}

-(void)showWindow:(id)sender {
	[[NSApp delegate] addObserver:self
					   forKeyPath:@"playbackManager.leftLevels"
						  options:NSKeyValueObservingOptionNew
						  context:nil];

	[[NSApp delegate] addObserver:self
					   forKeyPath:@"playbackManager.rightLevels"
						  options:NSKeyValueObservingOptionNew
						  context:nil];
	
	[super showWindow:sender];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"playbackManager.leftLevels"]) {
        
		if ([change valueForKey:NSKeyValueChangeNewKey] == [NSNull null])
			return;
		
		NSArray *levels = [change valueForKey:NSKeyValueChangeNewKey];
		if ([levels count] == 10) {
			
			self.leftValue1 = [levels objectAtIndex:0];
			self.leftValue2 = [levels objectAtIndex:1];
			self.leftValue3 = [levels objectAtIndex:2];
			self.leftValue4 = [levels objectAtIndex:3];
			self.leftValue5 = [levels objectAtIndex:4];
			self.leftValue6 = [levels objectAtIndex:5];
			self.leftValue7 = [levels objectAtIndex:6];
			self.leftValue8 = [levels objectAtIndex:7];
			self.leftValue9 = [levels objectAtIndex:8];
			self.leftValue10 = [levels objectAtIndex:9];
		}
		
    } else if ([keyPath isEqualToString:@"playbackManager.rightLevels"]) {
        
		if ([change valueForKey:NSKeyValueChangeNewKey] == [NSNull null])
			return;
		
		NSArray *levels = [change valueForKey:NSKeyValueChangeNewKey];
		if ([levels count] == 10) {
			
			self.rightValue1 = [levels objectAtIndex:0];
			self.rightValue2 = [levels objectAtIndex:1];
			self.rightValue3 = [levels objectAtIndex:2];
			self.rightValue4 = [levels objectAtIndex:3];
			self.rightValue5 = [levels objectAtIndex:4];
			self.rightValue6 = [levels objectAtIndex:5];
			self.rightValue7 = [levels objectAtIndex:6];
			self.rightValue8 = [levels objectAtIndex:7];
			self.rightValue9 = [levels objectAtIndex:8];
			self.rightValue10 = [levels objectAtIndex:9];
		}
		
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)dealloc {
	self.leftValue1 = nil;
	self.leftValue2 = nil;
	self.leftValue3 = nil;
	self.leftValue4 = nil;
	self.leftValue5 = nil;
	self.leftValue6 = nil;
	self.leftValue7 = nil;
	self.leftValue8 = nil;
	self.leftValue9 = nil;
	self.leftValue10 = nil;

	self.rightValue1 = nil;
	self.rightValue2 = nil;
	self.rightValue3 = nil;
	self.rightValue4 = nil;
	self.rightValue5 = nil;
	self.rightValue6 = nil;
	self.rightValue7 = nil;
	self.rightValue8 = nil;
	self.rightValue9 = nil;
	self.rightValue10 = nil;

	[super dealloc];
}

@end
