//
//  SPTrack+LocalFileExtensions.m
//  Viva
//
//  Created by Daniel Kennett on 06/02/2012.
//  For license information, see LICENSE.markdown
//

#import "SPTrack+LocalFileExtensions.h"
#import <objc/runtime.h>
#import "LocalFilesController.h"

@implementation SPTrack (LocalFileExtensions)

static const void *localFileKey = @"localFile";

-(LocalFile *)localFile {
	LocalFile *file = objc_getAssociatedObject(self, localFileKey);
	
	if (file && file.path.length > 0)
		return file;
	
	if (self.spotifyURL.spotifyLinkType != SP_LINKTYPE_LOCALTRACK)
		return nil;
	
	file = [[LocalFilesController sharedInstance] localFileForTrack:self];
	self.localFile = file;
	return file;
}

-(void)setLocalFile:(LocalFile *)localFile {
	objc_setAssociatedObject(self, localFileKey, localFile, OBJC_ASSOCIATION_RETAIN);
}

+(NSSet *)keyPathsForValuesAffectingResolvedTrackNumber {
	return [NSSet setWithObjects:@"localFile.trackNumber", @"trackNumber", nil];
}

-(NSUInteger)resolvedTrackNumber {
	if (self.localFile == nil)
		return self.trackNumber;
	else
		return [self.localFile.trackNumber unsignedIntegerValue];
}

+(NSSet *)keyPathsForValuesAffectingResolvedDiscNumber {
	return [NSSet setWithObjects:@"localFile.discNumber", @"discNumber", nil];
}

-(NSUInteger)resolvedDiscNumber {
	if (self.localFile == nil)
		return self.discNumber;
	else
		return [self.localFile.discNumber unsignedIntegerValue];
}

@end
