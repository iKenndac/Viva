//
//  SPVolumeSliderCell.m
//  Viva
//
//  Created by Daniel Kennett on 3/23/11.
//  For license information, see LICENSE.markdown
//

#import "SPVolumeSliderCell.h"

@implementation SPVolumeSliderCell

static NSImage *volumeKnobImage;
static NSImage *pressedVolumeKnobImage;

+(void)initialize {
	volumeKnobImage = [NSImage imageNamed:@"volumeball"];
	pressedVolumeKnobImage = [NSImage imageNamed:@"volumeball-pushed"];
}

- (void)drawKnob:(NSRect)knobRect {
	
	NSImage *imageToDraw = [self isHighlighted] ? pressedVolumeKnobImage : volumeKnobImage;
	
	[imageToDraw setFlipped:[[self controlView] isFlipped]];
	
	[imageToDraw drawInRect:knobRect
				   fromRect:NSZeroRect
				  operation:NSCompositeSourceOver
				   fraction:1.0];
}

-(NSRect)knobRectFlipped:(BOOL)flipped {
	
	if (NSEqualRects(NSZeroRect, lastFrame)) {
		return NSZeroRect;
	}
	
	double progress = ([self doubleValue] - [self minValue]) / ([self maxValue] - [self minValue]);
	
	NSRect rect = (NSRect) {
		.size = volumeKnobImage.size,
		.origin = NSMakePoint(floor((NSWidth(lastFrame) - [self knobThickness]) * progress),
							  floor(NSMidY(lastFrame) - (volumeKnobImage.size.height / 2) - 1.0))
	};
	
	return rect;
}

- (CGFloat)knobThickness {
	return volumeKnobImage.size.width;
}

@end
