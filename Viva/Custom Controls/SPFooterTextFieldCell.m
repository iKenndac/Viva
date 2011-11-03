//
//  SPFooterTextFieldCell.m
//  Viva
//
//  Created by Daniel Kennett on 04/04/2011.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "SPFooterTextFieldCell.h"


@implementation SPFooterTextFieldCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    
    NSRect drawingRect = [self drawingRectForBounds:cellFrame];
    NSMutableAttributedString *str = [[self attributedStringValue] mutableCopy];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowBlurRadius:0.0];
    [shadow setShadowOffset:NSMakeSize(0.0, 1.0)];
    
    [str addAttribute:NSShadowAttributeName
                value:shadow
                range:NSMakeRange(0, [str length])];
    
    [str drawInRect:drawingRect];
    
}

@end
