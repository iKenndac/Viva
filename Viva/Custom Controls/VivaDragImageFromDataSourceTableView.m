//
//  VivaDragImageFromDataSourceTableView.m
//  Viva
//
//  Created by Daniel Kennett on 16/04/2011.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaDragImageFromDataSourceTableView.h"


@implementation VivaDragImageFromDataSourceTableView

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent *)dragEvent offset:(NSPointPointer)dragImageOffset {	
	NSImage *ret = nil;
	
	if ([[self dataSource] respondsToSelector:@selector(tableView:dragImageForRowsWithIndexes:tableColumns:event:offset:)]) {
		ret = [(id <VivaTableViewDragImageProvider>)[self dataSource] tableView:self dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
	}
	
	if( ! ret ) {
		ret = [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
	}
	
	return ret;
}

-(void)keyDown:(NSEvent *)theEvent {
	
	if ([[theEvent characters] isEqualToString:@" "]) {
		if ([self.delegate respondsToSelector:@selector(keyDown:)]) {
			[(NSResponder *)self.delegate keyDown:theEvent];
		}
	} else {
		[super keyDown:theEvent];
	}
}

@end
