//
//  VivaTrackExtensions.m
//  Viva
//
//  Created by Daniel Kennett on 4/13/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaTrackExtensions.h"
#import "LocalFilesController.h"

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

+(NSSet *)keyPathsForValuesAffectingCondensedArtistForUIDisplay {
	return [NSSet setWithObject:@"artists"];
}

-(NSString *)condensedArtistForUIDisplay {
	if ([[self artists] count] > 1) {
		return [[[self artists] valueForKey:@"name"] componentsJoinedByString:@", "];
	}
	return nil;
}

+(NSSet *)keyPathsForValuesAffectingIsEnabledInUI {
	return [NSSet setWithObjects:@"availability", @"local", nil];
}

-(BOOL)isEnabledInUI {
	return (self.availability == SP_TRACK_AVAILABILITY_AVAILABLE ||
			self.isLocal);
}

+(NSSet *)keyPathsForValuesAffectingUiTextColor {
	return [NSSet setWithObject:@"isEnabledInUI"];
}

-(NSColor *)uiTextColor {
	return self.isEnabledInUI ? [NSColor blackColor] : [NSColor disabledControlTextColor];
}

-(LocalFile *)localFile {
	if (!self.isLocal) return nil;
	return [[LocalFilesController sharedInstance] localFileForTrack:self];
}

@end
