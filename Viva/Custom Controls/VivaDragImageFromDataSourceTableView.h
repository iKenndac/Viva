//
//  VivaDragImageFromDataSourceTableView.h
//  Viva
//
//  Created by Daniel Kennett on 16/04/2011.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VivaTableViewDragImageProvider 

-(NSImage *)tableView:(NSTableView *)tableView dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent *)dragEvent offset:(NSPointPointer)dragImageOffset;

@end

@interface VivaDragImageFromDataSourceTableView : NSTableView {
@private
    
}

@end
