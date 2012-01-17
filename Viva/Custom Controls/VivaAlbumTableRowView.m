//
//  VivaAlbumTableRowView.m
//  Viva
//
//  Created by Daniel Kennett on 06/12/2011.
//  For license information, see LICENSE.markdown
//

#import "VivaAlbumTableRowView.h"

@implementation VivaAlbumTableRowView

-(BOOL)isOpaque {
	return NO;
}

- (void)drawSelectionInRect:(NSRect)dirtyRect {
	
	// Create mask
	
	// Create a grayscale context for the mask
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
	CGContextRef maskContext = CGBitmapContextCreate(NULL,
													 self.bounds.size.width,
													 self.bounds.size.height,
													 8,
													 self.bounds.size.width,
													 colorspace,
													 0);
	CGColorSpaceRelease(colorspace);
	
	// Switch to the context for drawing
	NSGraphicsContext *maskGraphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:maskContext flipped:NO];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:maskGraphicsContext];
	
	NSGradient *fade = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:[NSColor whiteColor], [NSColor whiteColor], [NSColor blackColor], nil]];
	
	[fade drawInRect:self.bounds relativeCenterPosition:self.bounds.origin];
	
	// Switch back to the window's context
	[NSGraphicsContext restoreGraphicsState];
	
	// Create an image mask from what we've drawn so far
	CGImageRef alphaMask = CGBitmapContextCreateImage(maskContext);
	
	// Draw the image, clipped by the mask
	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	
	CGContextSaveGState(context);
	CGContextClipToMask(context, NSRectToCGRect(self.bounds), alphaMask);
	
	[[NSColor colorWithCalibratedRed:0.850 green:0.808 blue:0.647 alpha:1.000] set];
	NSRectFillUsingOperation(self.bounds, NSCompositeSourceOver);
	
	CGContextRestoreGState(context);
	CGImageRelease(alphaMask);
	
}

- (void)drawSeparatorInRect:(NSRect)dirtyRect {
	
	[[NSColor blackColor] set];
	
	NSRectFillUsingOperation(NSMakeRect(self.bounds.origin.x, self.bounds.origin.y - 1, self.bounds.size.width, 1.0),
							 NSCompositeSourceOver);
	
}

@end
