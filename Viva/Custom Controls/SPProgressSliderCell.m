//
//  SPProgressSliderCell.m
//  Viva
//
//  Created by Daniel Kennett on 3/23/11.
//  Copyright 2011 Spotify. All rights reserved.
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

+(void)initialize {
	trackImageLeft = [NSImage imageNamed:@"meeter-left"];
	trackImageMiddle = [NSImage imageNamed:@"meeter-middle"];
	trackImageRight = [NSImage imageNamed:@"meeter-right"];

	filledTrackImageLeft = [NSImage imageNamed:@"meeter-filled-left"];
	filledTrackImageMiddle = [NSImage imageNamed:@"meeter-filled-middle"];
	filledTrackImageRight = [NSImage imageNamed:@"meeter-filled-right"];

	knobImage = [NSImage imageNamed:@"trackball"];
	pressedKnobImage = [NSImage imageNamed:@"trackball-pushed"];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	//[super drawWithFrame:cellFrame inView:controlView];
	
	lastFrame = cellFrame;
	
	NSRect barFrame = (NSRect) {
		.size = NSMakeSize(cellFrame.size.width, trackImageLeft.size.height),
		.origin = NSMakePoint(cellFrame.origin.x, floor(cellFrame.size.height / 2) - (trackImageLeft.size.height / 2))
	};
	
	NSDrawThreePartImage(barFrame,
						 trackImageLeft,
						 trackImageMiddle, 
						 trackImageRight,
						 NO,
						 NSCompositeSourceOver,
						 1.0,
						 [controlView isFlipped]);
	
    if (self.isEnabled) {
        
        NSRect knobRect = [self knobRectFlipped:[controlView isFlipped]];
        
        if (NSMinX(knobRect) > 0.0) {
            NSRect filledBarFrame = barFrame;
            filledBarFrame.size.width = NSMidX(knobRect);
            
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
    }
		
	[[self controlView] setNeedsDisplayInRect:cellFrame];
}

-(NSRect)knobRectFlipped:(BOOL)flipped {
	
	if (NSEqualRects(NSZeroRect, lastFrame)) {
		return NSZeroRect;
	}

	double progress = ([self doubleValue] - [self minValue]) / ([self maxValue] - [self minValue]);
	
	NSRect rect = (NSRect) {
		.size = knobImage.size,
		.origin = NSMakePoint(floor((NSWidth(lastFrame) - [self knobThickness]) * progress),
							  floor(NSMidY(lastFrame) - (knobImage.size.height / 2) - 1.0))
	};
	
	return rect;
}

- (CGFloat)knobThickness {
	return knobImage.size.width;
}

- (void)drawKnob:(NSRect)knobRect {
	
	NSImage *imageToDraw = [self isHighlighted] ? pressedKnobImage : knobImage;
	
	[imageToDraw setFlipped:[[self controlView] isFlipped]];
	[imageToDraw drawInRect:knobRect
				   fromRect:NSZeroRect
				  operation:NSCompositeSourceOver
				   fraction:1.0];
}

@end
