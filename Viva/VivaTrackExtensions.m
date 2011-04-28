//
//  VivaTrackExtensions.m
//  Viva
//
//  Created by Daniel Kennett on 4/13/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaTrackExtensions.h"


@implementation SPTrack (VivaTrackExtensions)

+(NSSet *)keyPathsForValuesAffectingCondensedArtist {
	return [NSSet setWithObject:@"artists"];
}

-(NSString *)condensedArtist {
	if ([[self artists] count] > 0) {
		return [[[self artists] valueForKey:@"name"] componentsJoinedByString:@", "];
	}
	return nil;
}

@end
