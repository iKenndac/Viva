//
//  SPWithAlternateImageCell.m
//  Viva
//
//  Created by Daniel Kennett on 4/14/11.
//  For license information, see LICENSE.markdown
//

#import "SPWithAlternateImageCell.h"


@implementation SPWithAlternateImageCell

@synthesize alternateImage;

-(void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	NSImage *imageToDraw = [self image];
	
	if ([self isHighlighted] && ([self alternateImage] != nil)) {
		imageToDraw = [self alternateImage];
	}
	
	BOOL wasFlipped = [imageToDraw isFlipped];
	[imageToDraw setFlipped:[controlView isFlipped]];
	
	NSSize imageSize = [imageToDraw size];
	NSRect imageDrawRect = (NSRect) {
		.size = imageSize,
		.origin = NSMakePoint(floor(NSMidX(cellFrame) - (imageSize.width / 2)),
							  floor(NSMidY(cellFrame) - (imageSize.height / 2)))
	};
	
	[imageToDraw drawInRect:imageDrawRect
				   fromRect:NSZeroRect
				  operation:NSCompositeSourceOver
				   fraction:1.0];
	
	[imageToDraw setFlipped:wasFlipped];
}


@end
