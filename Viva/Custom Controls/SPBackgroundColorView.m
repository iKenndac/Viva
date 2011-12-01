//
//  SPBackgroundColorView.m
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "SPBackgroundColorView.h"


@implementation SPBackgroundColorView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

@synthesize  backgroundColor;

-(void)setBackgroundColor:(NSColor *)aBackgroundColor {
	if (aBackgroundColor != backgroundColor) {
		backgroundColor = aBackgroundColor;
		[self setNeedsDisplay:YES];
	}
}

-(BOOL)isOpaque {
	return NO;
}

-(BOOL)mouseDownCanMoveWindow {
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
	if (self.backgroundColor != nil) {
		[[NSGraphicsContext currentContext] saveGraphicsState];
		[self.backgroundColor set];
		NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
		[[NSGraphicsContext currentContext] restoreGraphicsState];
	}
}

@end
