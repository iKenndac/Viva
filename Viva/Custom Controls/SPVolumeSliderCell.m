//
//  SPVolumeSliderCell.m
//  Viva
//
//  Created by Daniel Kennett on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SPVolumeSliderCell.h"


@implementation SPVolumeSliderCell

static NSImage *volumeKnobImage;
static NSImage *pressedVolumeKnobImage;

- (void)drawKnob:(NSRect)knobRect {
	
	if (volumeKnobImage == nil) 
		volumeKnobImage = [[NSImage imageNamed:@"volumeball"] retain];
	
	if (pressedVolumeKnobImage == nil) 
		pressedVolumeKnobImage = [[NSImage imageNamed:@"volumeball-pushed"] retain];

	
	NSImage *imageToDraw = [self isHighlighted] ? pressedVolumeKnobImage : volumeKnobImage;
	
	[imageToDraw setFlipped:[[self controlView] isFlipped]];
	[imageToDraw drawInRect:knobRect
				   fromRect:NSZeroRect
				  operation:NSCompositeSourceOver
				   fraction:1.0];
}

@end
