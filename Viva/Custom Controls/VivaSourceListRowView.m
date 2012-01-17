//
//  VivaSourceListRowView.m
//  Viva
//
//  Created by Daniel Kennett on 07/12/2011.
//  For license information, see LICENSE.markdown
//

#import "VivaSourceListRowView.h"

@implementation VivaSourceListRowView

-(BOOL)isOpaque {
	return NO;
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
	
	NSColor *shadowColor = [[NSColor blackColor] colorWithAlphaComponent:0.2];
	NSColor *topLineColor = [NSColor colorWithCalibratedRed:0.475 green:0.475 blue:0.480 alpha:1.000];
	NSColor *gradientBeginColor = [NSColor colorWithCalibratedRed:0.333 green:0.333 blue:0.337 alpha:1.000];
	NSColor *gradientEndColor = [NSColor colorWithCalibratedRed:0.250 green:0.249 blue:0.253 alpha:1.000];
	
	[shadowColor set];
	NSRectFillUsingOperation(self.bounds, NSCompositeSourceOver);
	
	NSBezierPath *topLine = [[NSBezierPath alloc] init];
	[topLine moveToPoint:NSMakePoint(NSMinX(self.bounds) - 0.5, NSMinY(self.bounds) + 1.5)];
	[topLine lineToPoint:NSMakePoint(NSMaxX(self.bounds) + 0.5, NSMinY(self.bounds) + 1.5)];
	
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:gradientBeginColor endingColor:gradientEndColor];
	
	[gradient drawFromPoint:NSMakePoint(self.bounds.origin.x, NSMinY(self.bounds) + 1.5)
					toPoint:NSMakePoint(self.bounds.origin.x, NSMaxY(self.bounds) - 1.5)
					options:NSGradientNone];
	
	[topLineColor set];
	[topLine stroke];
	
	
	
}

@end
