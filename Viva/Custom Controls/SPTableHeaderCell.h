//
//  SPTableHeaderCell.h
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  For license information, see LICENSE.markdown
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
