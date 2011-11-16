//
//  LocalFileSource.h
//  Viva
//
//  Created by Daniel Kennett on 16/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LocalFile;

@interface LocalFileSource : NSManagedObject

@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSSet *localFiles;

@property (nonatomic, readonly) NSImage *icon;
@property (nonatomic, readonly) NSString *displayPath;

@property (nonatomic, readonly, getter = isActive) BOOL active;

-(void)performFullScan;
-(void)performUpdateScan;

@end

@interface LocalFileSource (CoreDataGeneratedAccessors)

- (void)addLocalFilesObject:(LocalFile *)value;
- (void)removeLocalFilesObject:(LocalFile *)value;
- (void)addLocalFiles:(NSSet *)values;
- (void)removeLocalFiles:(NSSet *)values;

@end
