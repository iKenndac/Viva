//
//  VivaAlbumBrowseExtensions.m
//  Viva
//
//  Created by Daniel Kennett on 4/24/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaAlbumBrowseExtensions.h"

@implementation SPSpotifyAlbumBrowse (VivaAlbumBrowseExtensions)

+(NSSet *)keyPathsForValuesAffectingCondensedCopyrights {
	return [NSSet setWithObject:@"copyrights"];
}

-(NSString *)condensedCopyrights {
	if (self.copyrights.count > 0) {
		return [self.copyrights componentsJoinedByString:@", "];
	} else {
		return nil;
	}
}

@end
