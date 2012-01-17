//
//  LocalFile.m
//  Viva
//
//  Created by Daniel Kennett on 16/11/2011.
//  For license information, see LICENSE.markdown
//

#import "LocalFile.h"
#import "LocalFileSource.h"


@implementation LocalFile

@dynamic album;
@dynamic artist;
@dynamic duration;
@dynamic path;
@dynamic title;
@dynamic source;

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@", [super description], self.path];
}

@end
