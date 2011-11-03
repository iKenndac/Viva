//
//  SPTableHeaderCell.m
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "SPTableHeaderCell.h"


@implementation SPTableHeaderCell

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		sortPriority = 1;
    }
    
    return self;
}


-(void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
	[style setAlignment:NSLeftTextAlignment];
	
	NSShadow *textShadow = [[NSShadow alloc] init];
	[textShadow setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:.6]];
	[textShadow setShadowBlurRadius:1.0];
	[textShadow setShadowOffset:NSMakeSize(0.0, 1.0)];
	
	NSDictionary *textAttribs = [NSDictionary dictionaryWithObjectsAndKeys:
								 [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]], NSFontAttributeName, 
								 textShadow, NSShadowAttributeName,
								 [[NSColor whiteColor] colorWithAlphaComponent:.9], NSForegroundColorAttributeName,
								 style, NSParagraphStyleAttributeName, 
								 nil];
	
	NSString *title = [self objectValue];
	
	NSSize textSize = [title sizeWithAttributes:textAttribs];
	NSRect textRect = (NSRect) {
		.origin = NSMakePoint(cellFrame.origin.x + 4.0, (cellFrame.size.height / 2) - (textSize.height / 2)),
		.size = NSMakeSize(cellFrame.size.width, textSize.height)
	};
	
	[title drawInRect:NSIntegralRect(textRect) withAttributes:textAttribs];
}

-(void)drawWithFrame:(NSRect)frame inView:(NSView *)view {
	
	NSImage *image = [NSImage imageNamed:[self state] == NSOnState ? @"sortbar-pressed" : @"sortbar"];
	[image setFlipped:YES];
	
	[image drawInRect:frame
			 fromRect:NSZeroRect
			operation:NSCompositeCopy
			 fraction:1.0];
	
	NSImage *separator = [NSImage imageNamed:@"sortbar-split"];
	NSRect separatorFrame = (NSRect) {
		.size = NSMakeSize(separator.size.width, frame.size.height),
		.origin = NSMakePoint(NSMaxX(frame) - separator.size.width, frame.origin.y)
	};
	
	[separator drawInRect:separatorFrame
				 fromRect:NSZeroRect
				operation:NSCompositeSourceOver
				 fraction:1.0];
	
	[self drawInteriorWithFrame:frame inView:view];
	[self drawSortIndicatorWithFrame:frame inView:view ascending:sortAscending priority:sortPriority];
}

-(id)copyWithZone:(NSZone *)zone {
    SPTableHeaderCell *cell = (SPTableHeaderCell *)[super copyWithZone:zone];
	cell->sortAscending = sortAscending;
	cell->sortPriority = sortPriority;
    return cell;
}

-(void)setSortAscending:(BOOL)asc priority:(NSInteger)pri {
	sortPriority = pri;
	sortAscending = asc;
}

-(NSInteger)sortPriority {
	return sortPriority;
}


@end
