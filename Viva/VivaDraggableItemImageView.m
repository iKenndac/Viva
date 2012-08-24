//
//  VivaDraggableItemImageView.m
//  Viva
//
//  Created by Daniel Kennett on 24/08/2012.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "VivaDraggableItemImageView.h"
#import "Constants.h"

@implementation VivaDraggableItemImageView

- (void)mouseDown:(NSEvent *)event
{
    
    NSSize size = self.image.size;
	NSPoint location = [self convertPoint:event.locationInWindow fromView:nil];
	location.x -= size.width / 2;
	location.y -= size.height / 2;
	//NSPoint location = NSMakePoint((self.bounds.size.width - size.width)/2, (self.bounds.size.height - size.height)/2);
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    if (event.clickCount > 1) return;
	if (self.itemURL == nil) return;

	[pboard clearContents];
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:@{kItemReferenceURL : self.itemURL}]
			forType:kSpotifyItemReferenceDragIdentifier];

	[self dragImage:self.image
				 at:location
			 offset:NSZeroSize
			  event:event
		 pasteboard:pboard
			 source:self
		  slideBack:YES];

}

@end
