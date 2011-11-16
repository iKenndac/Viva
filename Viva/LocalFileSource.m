//
//  LocalFileSource.m
//  Viva
//
//  Created by Daniel Kennett on 16/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import "LocalFileSource.h"
#import "LocalFile.h"
#import <AVFoundation/AVFoundation.h>

@interface LocalFileSource ()

@property (nonatomic, readwrite, getter = isActive) BOOL active;
-(LocalFile *)parseMediaFileAtPath:(NSString *)path intoContext:(NSManagedObjectContext *)context;
-(void)threadSafePerformScanOfDirectory:(NSString *)path withContext:(NSManagedObjectContext *)context;

@end

@implementation LocalFileSource

@dynamic path;
@dynamic localFiles;

@synthesize active;

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

#pragma mark Scanning

-(void)performFullScan {
	
	self.active = YES;
	[self performSelectorInBackground:@selector(performRecursiveScanOfDirectory:)
						   withObject:self.path];
	
}

-(void)performRecursiveScanOfDirectory:(NSString *)baseDirectory {
	
	@autoreleasepool {
		
		NSManagedObjectContext *threadContext = [[NSManagedObjectContext alloc] init];
		threadContext.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
		threadContext.undoManager = nil;
		
		LocalFileSource *threadSafeSelf = (LocalFileSource *)[threadContext objectWithID:self.objectID];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(threadedContextDidSave:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:threadContext];
		
		[threadSafeSelf threadSafePerformScanOfDirectory:baseDirectory withContext:threadContext];
		[threadContext save:nil];
		
		[self performSelectorOnMainThread:@selector(scanFinished)
							   withObject:nil
							waitUntilDone:NO];
		
	}
}

-(void)threadSafePerformScanOfDirectory:(NSString *)path withContext:(NSManagedObjectContext *)context {
	
	NSArray *allowedFileExtensions = [NSArray arrayWithObjects:@"mp3", @"m4a", nil];
	
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
	
	NSString *relativePath = nil;
	NSUInteger filesSinceLastSave = 0;
	
	while ((relativePath = [enumerator nextObject])) {
		
		@autoreleasepool {
			
			NSString *fullPath = [path stringByAppendingPathComponent:relativePath];
			
			if ([allowedFileExtensions containsObject:fullPath.pathExtension.lowercaseString]) {
				LocalFile *file = [self parseMediaFileAtPath:fullPath intoContext:context];
				if (file != nil) {
					[self addLocalFilesObject:file];
					filesSinceLastSave++;
				}
				
				if (filesSinceLastSave >= 50) {
					[context save:nil];
					filesSinceLastSave = 0;
				}
			}
		}
	}
}

-(LocalFile *)parseMediaFileAtPath:(NSString *)path intoContext:(NSManagedObjectContext *)context {
	
	AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
	
	NSArray *metaData = [asset commonMetadata];
	
	AVMetadataItem *titleItem = [[AVMetadataItem metadataItemsFromArray:metaData withKey:AVMetadataCommonKeyTitle keySpace:AVMetadataKeySpaceCommon] lastObject];
	AVMetadataItem *artistItem = [[AVMetadataItem metadataItemsFromArray:metaData withKey:AVMetadataCommonKeyArtist keySpace:AVMetadataKeySpaceCommon] lastObject];
	AVMetadataItem *albumItem = [[AVMetadataItem metadataItemsFromArray:metaData withKey:AVMetadataCommonKeyAlbumName keySpace:AVMetadataKeySpaceCommon] lastObject];
	
	NSString *title = [titleItem stringValue];
	NSString *artist = [artistItem stringValue];
	NSString *album = [albumItem stringValue];
	NSTimeInterval duration = CMTimeGetSeconds([asset duration]);
	
	if (title.length == 0) {
		title = [[path lastPathComponent] stringByDeletingPathExtension];
	}
	
	LocalFile *file = [[LocalFile alloc] initWithEntity:[NSEntityDescription entityForName:@"LocalFile" inManagedObjectContext:context]
						 insertIntoManagedObjectContext:context];
	
	file.title = title;
	file.artist = artist;
	file.album = album;
	file.path = path;
	file.duration = [NSNumber numberWithDouble:duration];
	
	return file;
}

-(void)scanFinished {
	self.active = NO;
}

-(void)threadedContextDidSave:(NSNotification *)notification {
	
	NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Merge+Save");
	
	NSManagedObjectContext *mainContext = self.managedObjectContext;
	[mainContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
								  withObject:notification
							   waitUntilDone:YES];
}

@end
