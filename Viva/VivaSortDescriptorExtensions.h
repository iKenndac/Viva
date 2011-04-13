//
//  VivaSortDescriptorExtensions.h
//  Viva
//
//  Created by Daniel Kennett on 4/13/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSSortDescriptor (VivaSortDescriptorExtensions)


+(NSArray *)trackSortDescriptorsForTitleAscending:(BOOL)ascending;
+(NSArray *)trackSortDescriptorsForAlbumAscending:(BOOL)ascending;
+(NSArray *)trackSortDescriptorsForArtistAscending:(BOOL)ascending;

@end
