//
//  LocalFileSource.m
//  Viva
//
//  Created by Daniel Kennett on 16/11/2011.
//  For license information, see LICENSE.markdown
//

#import "LocalFileSource.h"
#import "LocalFile.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreServices/CoreServices.h>
#import "LocalFileSource+LocalFileSourceFLACAdditions.h"

@interface LocalFileSource ()

@property (readwrite, getter = isActive) BOOL active;
@property (readwrite) BOOL fileSystemActivityOccurredDuringScan;

-(LocalFile *)parseMediaFileAtPath:(NSString *)path intoContext:(NSManagedObjectContext *)context;
-(LocalFile *)parseMediaFileWithAVFoundationAtPath:(NSString *)path intoContext:(NSManagedObjectContext *)context;
-(void)threadSafePerformFreshScanOfDirectory:(NSString *)path withContext:(NSManagedObjectContext *)context;
-(void)threadSafePerformUpdateScanOfDirectory:(NSString *)path withContext:(NSManagedObjectContext *)context;

-(void)addLocalFileAtPath:(NSString *)path context:(NSManagedObjectContext *)context;
-(void)removeLocalFileAtPath:(NSString *)path context:(NSManagedObjectContext *)context;
-(void)addLocalFilesInDirectory:(NSString *)path context:(NSManagedObjectContext *)context;
-(void)removeLocalFilesInDirectory:(NSString *)path context:(NSManagedObjectContext *)context;

@end

@implementation LocalFileSource {
	FSEventStreamRef eventStream;
	FSEventStreamContext *streamContext;
}

static NSArray *allowedFileExtensions;

+(void)initialize {
	if (allowedFileExtensions == nil)
		allowedFileExtensions = [NSArray arrayWithObjects:@"mp3", @"m4a", @"flac", nil];
}

@dynamic path;
@dynamic localFiles;

@synthesize active;
@synthesize fileSystemActivityOccurredDuringScan;

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

#pragma mark -
#pragma mark FSEvents

static void FSEventCallback(ConstFSEventStreamRef streamRef,
							void *clientCallBackInfo,
							size_t numEvents,
							void *eventPaths,
							const FSEventStreamEventFlags eventFlags[],
							const FSEventStreamEventId eventIds[]) {
	
	@autoreleasepool {
		
		LocalFileSource *self = (__bridge LocalFileSource *)clientCallBackInfo;
		
		// If we're scanning, don't screw with the model. Instead, set a flag and a rescan will happen.
		
		if (self.active) {
			NSLog(@"Filesystem activity during scan, deferring...");
			self.fileSystemActivityOccurredDuringScan = YES;
			return;
		}
		
		//Package everything up and bump it to another thread.
		
		NSArray *paths = (__bridge NSArray *)eventPaths;
		NSMutableArray *events = [NSMutableArray arrayWithCapacity:numEvents];
		
		for (NSUInteger currentEventIndex = 0; currentEventIndex < numEvents; currentEventIndex++) {
			
			NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
								   [paths objectAtIndex:currentEventIndex], @"path",
								   [NSNumber numberWithUnsignedInt:eventFlags[currentEventIndex]], @"flags", 
								   nil];
			
			[events addObject:event];
		}
		
		[self performSelectorInBackground:@selector(handleFSEventsOnBackgroundThread:)
							   withObject:events];
	}
}


-(void)startFSEventStream {
	
	NSLog(@"[%@ %@]: Starting observer on %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), self.path);
	
	if (eventStream != NULL)
		[self stopFSEventStream];
	
	NSArray *pathToWatch = [NSArray arrayWithObject:self.path];
	
	if (streamContext == NULL) {
		streamContext = malloc(sizeof(struct FSEventStreamContext));
		streamContext->info = (__bridge void *)self;
		streamContext->release = (CFAllocatorReleaseCallBack)CFRelease;
		streamContext->retain = (CFAllocatorRetainCallBack)CFRetain;
		streamContext->copyDescription = (CFAllocatorCopyDescriptionCallBack)CFCopyDescription;
		streamContext->version = 0;
	}
	
	eventStream = FSEventStreamCreate(kCFAllocatorDefault,
									  FSEventCallback,
									  streamContext,
									  (__bridge CFArrayRef)pathToWatch,
									  kFSEventStreamEventIdSinceNow,
									  2.0,
									  kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagIgnoreSelf | kFSEventStreamCreateFlagFileEvents);
	
	FSEventStreamScheduleWithRunLoop(eventStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	FSEventStreamStart(eventStream);
	
}

-(void)stopFSEventStream {
	
	if (eventStream == NULL) return;
	
	NSLog(@"[%@ %@]: Stopping Observer", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	FSEventStreamStop(eventStream);
	FSEventStreamInvalidate(eventStream);
	FSEventStreamRelease(eventStream);
	eventStream = NULL;
	
}

-(void)handleFSEventsOnBackgroundThread:(NSArray *)events {

	@autoreleasepool {
		
		NSManagedObjectContext *threadContext = [[NSManagedObjectContext alloc] init];
		threadContext.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
		threadContext.undoManager = nil;
		
		LocalFileSource *threadSafeSelf = (LocalFileSource *)[threadContext objectWithID:self.objectID];
		threadSafeSelf.active = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(threadedContextDidSave:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:threadContext];
		
		
		for (NSDictionary *event in events) {
			NSString *path = [event valueForKey:@"path"];
			FSEventStreamEventFlags flags = [[event valueForKey:@"flags"] unsignedIntValue];
			BOOL isFolder = (flags & kFSEventStreamEventFlagItemIsDir) != 0;
			
			if ((flags & kFSEventStreamEventFlagMustScanSubDirs) != 0) {
				// Have to rescan everything!
				[self performSelectorOnMainThread:@selector(performUpdateScan)
									   withObject:nil
									waitUntilDone:NO];
				return;
				
			} else if ((flags & kFSEventStreamEventFlagItemCreated) != 0) {
				
				if (isFolder) {
					[threadSafeSelf addLocalFilesInDirectory:path context:threadContext];
				} else {
					[threadSafeSelf addLocalFileAtPath:path context:threadContext];
				}
				
			} else if ((flags & kFSEventStreamEventFlagItemRemoved) != 0) {
				
				if (isFolder) {
					[threadSafeSelf removeLocalFilesInDirectory:path context:threadContext];
				} else {
					[threadSafeSelf removeLocalFileAtPath:path context:threadContext];
				}
				
			} else if ((flags & kFSEventStreamEventFlagItemRenamed) != 0) {
				
				if (isFolder) {
					if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
						[threadSafeSelf addLocalFilesInDirectory:path context:threadContext];
					} else {
						[threadSafeSelf removeLocalFilesInDirectory:path context:threadContext];
					}
					
				} else {
					if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
						[threadSafeSelf addLocalFileAtPath:path context:threadContext];
					} else {
						[threadSafeSelf removeLocalFileAtPath:path context:threadContext];
					}
				}
			}
		}
		
		[threadContext commitEditing];
		NSError *error = nil;
		[threadContext save:&error];
		if (error != nil)
			NSLog(@"Save error: %@", error);
		
		threadSafeSelf.active = NO;
		
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSManagedObjectContextDidSaveNotification
													  object:threadContext];

	}
}

#pragma mark -
#pragma mark Individual Events

-(void)addLocalFileAtPath:(NSString *)path context:(NSManagedObjectContext *)context {
	
	if (![allowedFileExtensions containsObject:path.pathExtension.lowercaseString])
		return;
	
	NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
							   path, @"TARGET_PATH",
							   nil];
	
	NSFetchRequest *request = [context.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"LocalFileAtPath"
																								substitutionVariables:variables];
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest:request error:&error];

	if (results.count > 0) {
		NSLog(@"Path already exists, skipping: %@", path);
		return;
	}
	
	LocalFile *file = [self parseMediaFileAtPath:path intoContext:context];
	NSLog(@"Adding %@", file.path);
	if (file != nil)
		[self addLocalFilesObject:file];
}

-(void)removeLocalFileAtPath:(NSString *)path context:(NSManagedObjectContext *)context {
	
	NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
							   path, @"TARGET_PATH",
							   nil];
	
	NSFetchRequest *request = [context.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"LocalFileAtPath"
																								substitutionVariables:variables];
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest:request error:&error];
	
	NSLog(@"Removing %@", [results valueForKey:@"path"]);
	
	for (LocalFile *file in results) {
		[self removeLocalFilesObject:file];
		[context deleteObject:file];
	}

}

-(void)addLocalFilesInDirectory:(NSString *)path context:(NSManagedObjectContext *)context {
	
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
	NSString *relativePath = nil;
	
	while ((relativePath = [enumerator nextObject])) {
		[self addLocalFileAtPath:[path stringByAppendingPathComponent:relativePath]
						 context:context];
	}
}

-(void)removeLocalFilesInDirectory:(NSString *)path context:(NSManagedObjectContext *)context {
	
	NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
							   path, @"TARGET_PATH",
							   nil];
	
	NSFetchRequest *request = [context.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"LocalFilesUnderPath"
																								substitutionVariables:variables];
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest:request error:&error];
	
	NSLog(@"Removing %@", [results valueForKey:@"path"]);
	
	for (LocalFile *file in results) {
		[self removeLocalFilesObject:file];
		[context deleteObject:file];
	}
}

#pragma mark -
#pragma mark Update Scan

-(void)performUpdateScan {
	
	self.fileSystemActivityOccurredDuringScan = NO;
	self.active = YES;
	[self performSelectorInBackground:@selector(threadSafePerformUpdateScanOfDirectory:)
						   withObject:self.path];
	
}

-(void)threadSafePerformUpdateScanOfDirectory:(NSString *)baseDirectory {
	
	@autoreleasepool {
		
		NSManagedObjectContext *threadContext = [[NSManagedObjectContext alloc] init];
		threadContext.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
		threadContext.undoManager = nil;
		
		LocalFileSource *threadSafeSelf = (LocalFileSource *)[threadContext objectWithID:self.objectID];
		threadSafeSelf.active = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(threadedContextDidSave:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:threadContext];
		
		[threadSafeSelf threadSafePerformUpdateScanOfDirectory:baseDirectory withContext:threadContext];
		[threadContext commitEditing];
		[threadContext save:nil];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSManagedObjectContextDidSaveNotification
													  object:threadContext];
		
		threadSafeSelf.active = NO;
		
		[self performSelectorOnMainThread:@selector(scanFinished)
							   withObject:nil
							waitUntilDone:NO];
	}
}

-(void)threadSafePerformUpdateScanOfDirectory:(NSString *)path withContext:(NSManagedObjectContext *)context {
	
	NSSet *localFileSnapshot = [self.localFiles copy];
	NSMutableSet *localFilesToBeDeleted = [localFileSnapshot mutableCopy];
	NSMutableArray *freshPaths = [NSMutableArray arrayWithCapacity:localFileSnapshot.count];
	
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
	NSString *relativePath = nil;
	
	while ((relativePath = [enumerator nextObject])) {
		
		if ([allowedFileExtensions containsObject:relativePath.pathExtension.lowercaseString])
			[freshPaths addObject:[path stringByAppendingPathComponent:relativePath]];
	}
	
	NSMutableSet *activeFiles = [NSMutableSet setWithCapacity:freshPaths.count];
	
	for (LocalFile *localFile in localFileSnapshot) {
		if ([freshPaths containsObject:localFile.path]) {
			[activeFiles addObject:localFile];
			[freshPaths removeObject:localFile.path];
			[localFilesToBeDeleted removeObject:localFile];
		}
	}
	
	NSLog(@"[%@ %@]: %@ new files.", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [NSNumber numberWithUnsignedInteger:freshPaths.count]);
	
	for (NSString *path in freshPaths) {
		LocalFile *file = [self parseMediaFileAtPath:path intoContext:context];
		if (file != nil)
			[activeFiles addObject:file];
	}
	
	[self setLocalFiles:activeFiles];
	
	for (LocalFile *localFile in localFilesToBeDeleted) {
		[context deleteObject:localFile];
	}
}

#pragma mark -
#pragma mark Full Scan

-(void)performFullScan {
	
	self.fileSystemActivityOccurredDuringScan = NO;
	self.active = YES;
	[self performSelectorInBackground:@selector(threadSafePerformFreshScanOfDirectory:)
						   withObject:self.path];
	
}

-(void)threadSafePerformFreshScanOfDirectory:(NSString *)baseDirectory {
	
	@autoreleasepool {
		
		NSManagedObjectContext *threadContext = [[NSManagedObjectContext alloc] init];
		threadContext.persistentStoreCoordinator = self.managedObjectContext.persistentStoreCoordinator;
		threadContext.undoManager = nil;
		
		LocalFileSource *threadSafeSelf = (LocalFileSource *)[threadContext objectWithID:self.objectID];
		threadSafeSelf.active = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(threadedContextDidSave:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:threadContext];
		
		[threadSafeSelf threadSafePerformFreshScanOfDirectory:baseDirectory withContext:threadContext];
		[threadContext commitEditing];
		[threadContext save:nil];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSManagedObjectContextDidSaveNotification
													  object:threadContext];
		
		threadSafeSelf.active = NO;
		
		[self performSelectorOnMainThread:@selector(scanFinished)
							   withObject:nil
							waitUntilDone:NO];
	}
}

-(void)threadSafePerformFreshScanOfDirectory:(NSString *)path withContext:(NSManagedObjectContext *)context {
	
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
					[context commitEditing];
					[context save:nil];
					filesSinceLastSave = 0;
				}
			}
		}
	}
}

#pragma mark -
#pragma mark Scan helpers

-(LocalFile *)parseMediaFileAtPath:(NSString *)path intoContext:(NSManagedObjectContext *)context {
	
	if ([[path pathExtension] caseInsensitiveCompare:@"flac"] == NSOrderedSame) {
		return [self parseMediaFileWithFLACAtPath:path intoContext:context];
	} else {
		return [self parseMediaFileWithAVFoundationAtPath:path intoContext:context];
	}
}

-(LocalFile *)parseMediaFileWithAVFoundationAtPath:(NSString *)path intoContext:(NSManagedObjectContext *)context {
	
	AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
	
	NSArray *metaData = [asset commonMetadata];
	NSArray *iTunesMetaData = [asset metadataForFormat:AVMetadataFormatiTunesMetadata];
	NSArray *id3MetaData = [asset metadataForFormat:AVMetadataFormatID3Metadata];
	
	AVMetadataItem *titleItem = [[AVMetadataItem metadataItemsFromArray:metaData withKey:AVMetadataCommonKeyTitle keySpace:AVMetadataKeySpaceCommon] lastObject];
	AVMetadataItem *artistItem = [[AVMetadataItem metadataItemsFromArray:metaData withKey:AVMetadataCommonKeyArtist keySpace:AVMetadataKeySpaceCommon] lastObject];
	AVMetadataItem *albumItem = [[AVMetadataItem metadataItemsFromArray:metaData withKey:AVMetadataCommonKeyAlbumName keySpace:AVMetadataKeySpaceCommon] lastObject];
	
	NSString *title = [titleItem stringValue];
	NSString *artist = [artistItem stringValue];
	NSString *album = [albumItem stringValue];
	NSTimeInterval duration = CMTimeGetSeconds([asset duration]);
	
	AVMetadataItem *trackNumberItem = [[AVMetadataItem metadataItemsFromArray:iTunesMetaData withKey:AVMetadataiTunesMetadataKeyTrackNumber keySpace:AVMetadataKeySpaceiTunes] lastObject];
	NSNumber *trackNumber = nil;
	
	if (trackNumberItem != nil) {
		// This is an MP4 atom
		NSData *data = [trackNumberItem dataValue];
		
		if (data.length == 8) {
			UInt16 *values = (UInt16 *)[[trackNumberItem dataValue] bytes];
			UInt16 track = EndianU16_BtoN(values[1]);
			//UInt16 trackOf = EndianU16_BtoN(values[2]);
			trackNumber = [NSNumber numberWithUnsignedInt:track];
		}
	}
	
	if (trackNumber == nil) {
		// No atom metadata, maybe ID3
		trackNumberItem = [[AVMetadataItem metadataItemsFromArray:id3MetaData withKey:AVMetadataID3MetadataKeyTrackNumber keySpace:AVMetadataKeySpaceID3] lastObject];
		NSString *trackNumberString = [trackNumberItem stringValue];
		NSRange trackNumberDividerRange = [trackNumberString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/-"]];
		
		if (trackNumberDividerRange.location == NSNotFound) {
			trackNumber = [NSNumber numberWithInteger:[trackNumberString integerValue]];
		} else {
			trackNumber = [NSNumber numberWithInteger:[[trackNumberString substringToIndex:trackNumberDividerRange.location] integerValue]];
		}
	}
	
	AVMetadataItem *discNumberItem = [[AVMetadataItem metadataItemsFromArray:iTunesMetaData withKey:AVMetadataiTunesMetadataKeyDiscNumber keySpace:AVMetadataKeySpaceiTunes] lastObject];
	NSNumber *discNumber = nil;
	
	if (discNumberItem != nil) {
		// This is an MP4 atom
		NSData *data = [discNumberItem dataValue];
		
		if (data.length == 6) {
			UInt16 *values = (UInt16 *)[[discNumberItem dataValue] bytes];
			UInt16 disc = EndianU16_BtoN(values[1]);
			//UInt16 discOf = EndianU16_BtoN(values[2]);
			discNumber = [NSNumber numberWithUnsignedInt:disc];
		}
	}
	
	if (discNumber == nil) {
		// No atom metadata, maybe ID3
		discNumberItem = [[AVMetadataItem metadataItemsFromArray:id3MetaData withKey:AVMetadataID3MetadataKeyPartOfASet keySpace:AVMetadataKeySpaceID3] lastObject];
		NSString *discNumberString = [discNumberItem stringValue];
		NSRange discNumberDividerRange = [discNumberString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/-"]];
		
		if (discNumberDividerRange.location == NSNotFound) {
			discNumber = [NSNumber numberWithInteger:[discNumberString integerValue]];
		} else {
			discNumber = [NSNumber numberWithInteger:[[discNumberString substringToIndex:discNumberDividerRange.location] integerValue]];
		}
	}
	
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
	file.trackNumber = trackNumber;
	file.discNumber = discNumber;
	
	return file;
}

-(void)scanFinished {
	self.active = NO;
	if (self.fileSystemActivityOccurredDuringScan) {
		NSLog(@"Filesystem activity during scan, updating...");
		self.fileSystemActivityOccurredDuringScan = NO;
		[self performUpdateScan];
	}
}

-(void)threadedContextDidSave:(NSNotification *)notification {
	NSManagedObjectContext *mainContext = self.managedObjectContext;
	[mainContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
								  withObject:notification
							   waitUntilDone:YES];
}

-(void)dealloc {
	if (eventStream != NULL)
		free(eventStream);
}

@end
