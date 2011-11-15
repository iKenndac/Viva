//
//  LocalFileSource.m
//  Viva
//
//  Created by Daniel Kennett on 15/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import "LocalFileSource.h"
#import "LocalFile.h"


@implementation LocalFileSource

@dynamic path;
@dynamic localFiles;

+(NSSet *)keyPathsForValuesAffectingDisplayPath {
	return [NSSet setWithObject:@"path"];
}

-(NSString *)displayPath {
	return [self.path stringByAbbreviatingWithTildeInPath];
}

+(NSSet *)keyPathsForValuesAffectingIcon {
	return [NSSet setWithObject:@"path"];
}

-(NSImage *)icon {
	if (self.path.length == 0) return nil;
	return [[NSWorkspace sharedWorkspace] iconForFile:self.path];
}

@end
