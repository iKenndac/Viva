//
//  VivaSortDescriptorExtensions.m
//  Viva
//
//  Created by Daniel Kennett on 4/13/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaSortDescriptorExtensions.h"

@implementation NSSortDescriptor (VivaSortDescriptorExtensions)

+(NSArray *)trackSortDescriptorsForTitleAscending:(BOOL)ascending {
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:ascending selector:@selector(caseInsensitiveCompare:)]];
}

+(NSArray *)trackSortDescriptorsForAlbumAscending:(BOOL)ascending {
	return [NSArray arrayWithObjects:
			[NSSortDescriptor sortDescriptorWithKey:@"album.name" ascending:ascending selector:@selector(caseInsensitiveCompare:)],
			[NSSortDescriptor sortDescriptorWithKey:@"discNumber" ascending:YES selector:@selector(compare:)],
			[NSSortDescriptor sortDescriptorWithKey:@"trackNumber" ascending:YES selector:@selector(compare:)],
			nil];
}

+(NSArray *)trackSortDescriptorsForArtistAscending:(BOOL)ascending {
	
	return [[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"album.artist.name" ascending:ascending selector:@selector(caseInsensitiveCompare:)]]
			arrayByAddingObjectsFromArray:[self trackSortDescriptorsForAlbumAscending:ascending]];
	
}

@end
