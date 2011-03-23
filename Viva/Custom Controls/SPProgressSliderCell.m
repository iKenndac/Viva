//
//  SPProgressSliderCell.m
//  Viva
//
//  Created by Daniel Kennett on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SPProgressSliderCell.h"


@implementation SPProgressSliderCell

static NSImage *trackImageLeft;
static NSImage *trackImageMiddle;
static NSImage *trackImageRight;
static NSImage *filledTrackImageLeft;
static NSImage *filledTrackImageMiddle;
static NSImage *filledTrackImageRight;
static NSImage *knobImage;
static NSImage *pressedKnobImage;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		

	}
    
    return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	lastFrame = cellFrame;
	
	if (trackImageLeft == nil) {
		trackImageLeft = [[NSImage imageNamed:@"meeter-left"] retain];
		trackImageMiddle = [[NSImage imageNamed:@"meeter-middle"] retain];
		trackImageRight = [[NSImage imageNamed:@"meeter-right"] retain];
	}
	
	if (filledTrackImageLeft == nil) {
		filledTrackImageLeft = [[NSImage imageNamed:@"meeter-filled-left"] retain];
		filledTrackImageMiddle = [[NSImage imageNamed:@"meeter-filled-middle"] retain];
		filledTrackImageRight = [[NSImage imageNamed:@"meeter-filled-right"] retain];
	}
	
	NSRect barFrame = (NSRect) {
		.size = NSMakeSize(cellFrame.size.width, trackImageLeft.size.height),
		.origin = NSMakePoint(cellFrame.origin.x, (cellFrame.size.height / 2) - (trackImageLeft.size.height / 2))
	};
	
	barFrame = NSOffsetRect(NSIntegralRect(barFrame), .0, .0);
	
	NSDrawThreePartImage(barFrame,
						 trackImageLeft,
						 trackImageMiddle, 
						 trackImageRight,
						 NO,
						 NSCompositeSourceOver,
						 1.0,
						 [controlView isFlipped]);
	
	NSRect knobRect = [self knobRectFlipped:[controlView isFlipped]];
	
	if (NSMinX(knobRect) > 0.0) {
		NSRect filledBarFrame = barFrame;
		filledBarFrame.size.width = NSMaxX(knobRect);
		
		NSDrawThreePartImage(filledBarFrame,
							 filledTrackImageLeft,
							 filledTrackImageMiddle, 
							 filledTrackImageRight,
							 NO,
							 NSCompositeSourceOver,
							 1.0,
							 [controlView isFlipped]);
	}
	
	[self drawKnob:knobRect];
		
	[[self controlView] setNeedsDisplayInRect:cellFrame];
}

-(NSRect)knobRectFlipped:(BOOL)flipped {
	
	double progress = ([self doubleValue] - [self minValue]) / ([self maxValue] - [self minValue]);
	
	NSRect rect = (NSRect) {
		.size = knobImage.size,
		.origin = NSMakePoint(floor((NSWidth(lastFrame) - [self knobThickness]) * progress),
							  NSMidY(lastFrame) - (knobImage.size.height / 2))
	};
	
	return rect;
							  
}

- (CGFloat)knobThickness {
	return knobImage.size.width;
}

- (void)drawKnob:(NSRect)knobRect {
	
	if (knobImage == nil) 
		knobImage = [[NSImage imageNamed:@"trackball"] retain];
	
	if (pressedKnobImage == nil) 
		pressedKnobImage = [[NSImage imageNamed:@"trackball-pushed"] retain];
	
	NSImage *imageToDraw = [self isHighlighted] ? pressedKnobImage : knobImage;
	
	[imageToDraw setFlipped:[[self controlView] isFlipped]];
	[imageToDraw drawInRect:knobRect
				   fromRect:NSZeroRect
				  operation:NSCompositeSourceOver
				   fraction:1.0];
}

@end
