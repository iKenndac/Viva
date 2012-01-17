//
//  SPTableCorner.m
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  For license information, see LICENSE.markdown
//

#import "SPTableCorner.h"


@implementation SPTableCorner

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
	NSImage *image = [NSImage imageNamed:@"sortbar"];
	[image setFlipped:[self isFlipped]];
	
	[image drawInRect:self.bounds
			 fromRect:NSZeroRect
			operation:NSCompositeCopy
			 fraction:1.0];

}

@end
