//
//  SPSplitView.m
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  Copyright 2011 Spotify. All rights reserved.
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
