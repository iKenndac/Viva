//
//  SPTrack+LocalFileExtensions.m
//  Viva
//
//  Created by Daniel Kennett on 06/02/2012.
//  For license information, see LICENSE.markdown
//

#import "SPTrack+LocalFileExtensions.h"
#import <objc/runtime.h>

@implementation SPTrack (LocalFileExtensions)

static const void *localFileKey = @"localFile";

-(LocalFile *)localFile {
	return objc_getAssociatedObject(self, localFileKey);
}

-(void)setLocalFile:(LocalFile *)localFile {
	objc_setAssociatedObject(self, localFileKey, localFile, OBJC_ASSOCIATION_RETAIN);
}

-(NSUInteger)trackNumber {
	if (self.localFile == nil)
		return sp_track_index(self.track);
	else
		return [self.localFile.trackNumber unsignedIntegerValue];
}

-(NSUInteger)discNumber {
	if (self.localFile == nil)
		return sp_track_disc(self.track);
	else
		return [self.localFile.discNumber unsignedIntegerValue];
}

@end
