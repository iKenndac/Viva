//
//  SPBackgroundImageView.m
//  Viva
//
//  Created by Daniel Kennett on 6/13/11.
//  For license information, see LICENSE.markdown
//

#import "SPBackgroundImageView.h"

@implementation SPBackgroundImageView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

@synthesize backgroundImage;

-(void)setBackgroundImage:(NSImage *)aBackgroundImage {
	if (aBackgroundImage != backgroundImage) {
		backgroundImage = aBackgroundImage;
		[self setNeedsDisplay:YES];
	}
}

- (void)dealloc
{
	self.backgroundImage = nil;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
	if (self.backgroundImage != nil) {
		
		NSSize imageSize = self.backgroundImage.size;
		if (NSEqualSizes(imageSize, NSZeroSize)) return;
		
		[[NSGraphicsContext currentContext] saveGraphicsState];
		[[NSBezierPath bezierPathWithRect:dirtyRect] setClip];
		 
		for (CGFloat currentRow = 0.0; currentRow <= NSMaxX(dirtyRect); currentRow += imageSize.width) {
			for (CGFloat currentColumn = 0.0; currentColumn <= NSMaxY(dirtyRect); currentColumn += imageSize.height) {
				NSRect tile = NSMakeRect(currentRow, currentColumn, imageSize.width, imageSize.height);
				if (NSIntersectsRect(tile, dirtyRect))
					[self.backgroundImage drawInRect:tile
											fromRect:NSZeroRect
										   operation:NSCompositeSourceOver
											fraction:1.0];
			}
		}
		
		[[NSGraphicsContext currentContext] restoreGraphicsState];
	}
}

@end
