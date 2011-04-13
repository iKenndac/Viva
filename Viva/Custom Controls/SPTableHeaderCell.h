//
//  SPTableHeaderCell.h
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SPTableHeaderCell : NSTableHeaderCell {
@private
    BOOL sortAscending;
	NSInteger sortPriority;
}

-(void)setSortAscending:(BOOL)asc priority:(NSInteger)pri;
-(NSInteger)sortPriority;

@end
