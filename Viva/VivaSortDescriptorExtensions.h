//
//  VivaSortDescriptorExtensions.h
//  Viva
//
//  Created by Daniel Kennett on 4/13/11.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>


@interface NSSortDescriptor (VivaSortDescriptorExtensions)


+(NSArray *)trackContainerSortDescriptorsForTitleAscending:(BOOL)ascending;
+(NSArray *)trackContainerSortDescriptorsForAlbumAscending:(BOOL)ascending;
+(NSArray *)trackContainerSortDescriptorsForArtistAscending:(BOOL)ascending;

@end
