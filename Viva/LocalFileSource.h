//
//  LocalFileSource.h
//  Viva
//
//  Created by Daniel Kennett on 16/11/2011.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LocalFile;

@interface LocalFileSource : NSManagedObject

@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSSet *localFiles;

@property (nonatomic, readonly) NSImage *icon;
@property (nonatomic, readonly) NSString *displayPath;

@property (readonly, getter = isActive) BOOL active;

-(void)performFullScan;
-(void)performUpdateScan;

-(void)startFSEventStream;
-(void)stopFSEventStream;


@end

@interface LocalFileSource (CoreDataGeneratedAccessors)

- (void)addLocalFilesObject:(LocalFile *)value;
- (void)removeLocalFilesObject:(LocalFile *)value;
- (void)addLocalFiles:(NSSet *)values;
- (void)removeLocalFiles:(NSSet *)values;

@end
