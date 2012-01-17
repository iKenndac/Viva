//
//  VivaDragImageFromDataSourceTableView.h
//  Viva
//
//  Created by Daniel Kennett on 16/04/2011.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>

@protocol VivaTableViewDragImageProvider 

-(NSImage *)tableView:(NSTableView *)tableView dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent *)dragEvent offset:(NSPointPointer)dragImageOffset;

@end

@interface VivaDragImageFromDataSourceTableView : NSTableView {
@private
    
}

@end
