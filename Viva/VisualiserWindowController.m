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
		[NSApp addObserver:self
				forKeyPath:@"delegate.playbackManager.leftLevels"
				   options:NSKeyValueObservingOptionNew
				   context:nil];
		
		[NSApp addObserver:self
				forKeyPath:@"delegate.playbackManager.rightLevels"
				   options:NSKeyValueObservingOptionNew
				   context:nil];
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
@synthesize leftValue11;
@synthesize leftValue12;
@synthesize leftValue13;
@synthesize leftValue14;
@synthesize leftValue15;
@synthesize leftValue16;

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
@synthesize rightValue11;
@synthesize rightValue12;
@synthesize rightValue13;
@synthesize rightValue14;
@synthesize rightValue15;
@synthesize rightValue16;

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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"delegate.playbackManager.leftLevels"]) {
        
		if ([change valueForKey:NSKeyValueChangeNewKey] == [NSNull null])
			return;
		
		NSArray *levels = [change valueForKey:NSKeyValueChangeNewKey];
		if ([levels count] >= 16) {
			
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
			self.leftValue11 = [levels objectAtIndex:10];
			self.leftValue12 = [levels objectAtIndex:11];
			self.leftValue13 = [levels objectAtIndex:12];
			self.leftValue14 = [levels objectAtIndex:13];
			self.leftValue15 = [levels objectAtIndex:14];
			self.leftValue16 = [levels objectAtIndex:15];
		}
		
    } else if ([keyPath isEqualToString:@"delegate.playbackManager.rightLevels"]) {
        
		if ([change valueForKey:NSKeyValueChangeNewKey] == [NSNull null])
			return;
		
		NSArray *levels = [change valueForKey:NSKeyValueChangeNewKey];
		if ([levels count] >= 16) {
			
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
			self.rightValue11 = [levels objectAtIndex:10];
			self.rightValue12 = [levels objectAtIndex:11];
			self.rightValue13 = [levels objectAtIndex:12];
			self.rightValue14 = [levels objectAtIndex:13];
			self.rightValue15 = [levels objectAtIndex:14];
			self.rightValue16 = [levels objectAtIndex:15];
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
	self.leftValue11 = nil;
	self.leftValue12 = nil;
	self.leftValue13 = nil;
	self.leftValue14 = nil;
	self.leftValue15 = nil;
	self.leftValue16 = nil;

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
	self.rightValue11 = nil;
	self.rightValue12 = nil;
	self.rightValue13 = nil;
	self.rightValue14 = nil;
	self.rightValue15 = nil;
	self.rightValue16 = nil;
	
	[NSApp removeObserver:self forKeyPath:@"delegate.playbackManager.leftLevels"];
	[NSApp removeObserver:self forKeyPath:@"delegate.playbackManager.rightLevels"];
	
	[super dealloc];
}

@end
