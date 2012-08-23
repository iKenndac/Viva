//
//  VivaSortDescriptorExtensions.m
//  Viva
//
//  Created by Daniel Kennett on 4/13/11.
//  For license information, see LICENSE.markdown
//

#import "VivaSortDescriptorExtensions.h"

@implementation NSSortDescriptor (VivaSortDescriptorExtensions)

+(NSArray *)trackContainerSortDescriptorsForTitleAscending:(BOOL)ascending {
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"track.name" ascending:ascending selector:@selector(caseInsensitiveCompare:)]];
}

+(NSArray *)trackContainerSortDescriptorsForAlbumAscending:(BOOL)ascending {
	return [NSArray arrayWithObjects:
			[NSSortDescriptor sortDescriptorWithKey:@"track.album.name" ascending:ascending selector:@selector(caseInsensitiveCompare:)],
			[NSSortDescriptor sortDescriptorWithKey:@"track.resolvedDiscNumber" ascending:YES selector:@selector(compare:)],
			[NSSortDescriptor sortDescriptorWithKey:@"track.resolvedTrackNumber" ascending:YES selector:@selector(compare:)],
			nil];
}

+(NSArray *)trackContainerSortDescriptorsForArtistAscending:(BOOL)ascending {
	
	return [[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"track.album.artist.name" ascending:ascending selector:@selector(caseInsensitiveCompare:)]]
			arrayByAddingObjectsFromArray:[self trackContainerSortDescriptorsForAlbumAscending:ascending]];
	
}

@end
