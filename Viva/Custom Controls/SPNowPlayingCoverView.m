//
//  SPNowPlayingCoverView.m
//  Viva
//
//  Created by Daniel Kennett on 01/12/2011.
//  For license information, see LICENSE.markdown
//

#import "SPNowPlayingCoverView.h"

@implementation SPNowPlayingCoverView

@synthesize image;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self addObserver:self forKeyPath:@"image" options:0 context:nil];
    }
    
    return self;
}

-(BOOL)isOpaque {
	return NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"image"]) {
        [self setNeedsDisplay:YES];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
	
	NSImage *imageToDraw = self.image != nil ? self.image : [NSImage imageNamed:@"64-album"];
	
	NSRect borderRect = NSOffsetRect(NSInsetRect(self.bounds, 1.0, 1.0), 0.5, 0.5);
	
	NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:borderRect xRadius:2.0 yRadius:2.0];
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	NSShadow *shadow = [[NSShadow alloc] init];
	shadow.shadowColor = [[NSColor whiteColor] colorWithAlphaComponent:0.5];
	shadow.shadowBlurRadius = 0.0;
	shadow.shadowOffset = NSMakeSize(0.0, -1.0);
	
	[shadow set];
	[borderPath fill];
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	[borderPath setClip];
	
	NSRect imageSourceRect = imageToDraw.size.width > imageToDraw.size.height ?
		NSMakeRect((imageToDraw.size.width / 2) - (imageToDraw.size.height / 2), 0.0, imageToDraw.size.height, imageToDraw.size.height) :
		NSMakeRect(0.0, (imageToDraw.size.height / 2) - (imageToDraw.size.width / 2), imageToDraw.size.width, imageToDraw.size.width);
	
	[imageToDraw drawInRect:NSIntegralRect(borderRect) fromRect:imageSourceRect operation:NSCompositeSourceOver fraction:1.0];
	
	[[[NSColor darkGrayColor] colorWithAlphaComponent:0.2] set];
	[[NSBezierPath bezierPathWithRoundedRect:NSOffsetRect(borderRect, 0.0, -1.0) xRadius:2.0 yRadius:2.0] stroke];
	
	[[NSColor darkGrayColor] set];
	[borderPath stroke];
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"image"];
}

@end
