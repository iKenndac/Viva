//
//  SPSplitView.m
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  For license information, see LICENSE.markdown
//

#import "SPSplitView.h"


@implementation SPSplitView

- (void)drawDividerInRect:(NSRect)aRect
{	
	if ([self dividerStyle] == NSSplitViewDividerStyleThin) {
        
        [[NSColor blackColor] set];
        NSRectFill(aRect);
        
    } else {
        [super drawDividerInRect:aRect];
    }
}

@end
