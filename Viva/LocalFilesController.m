//
//  LocalFilesController.m
//  Viva
//
//  Created by Daniel Kennett on 15/11/2011.
//  For license information, see LICENSE.markdown
//

#import "LocalFilesController.h"

@interface LocalFilesController ()

@property (nonatomic, readwrite, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readwrite, strong) NSPersistentStoreCoordinator *storeCoordinator;
@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;

-(void)commit;

@end

@implementation LocalFilesController

static LocalFilesController *sharedInstance;

+(LocalFilesController *)sharedInstance {
	if (sharedInstance == nil) {
		sharedInstance = [[LocalFilesController alloc] init]; 
	}
	
	return sharedInstance;
}

-(id)init {
	
	if (sharedInstance)
		return sharedInstance;
    
    self = [super init];
    
    if (self) {
        
        // Model
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"LocalFiles" withExtension:@"momd"];
        self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
        // Persistent Store
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *libraryURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
        libraryURL = [libraryURL URLByAppendingPathComponent:[[SPSession sharedSession] userAgent]];
                
        NSURL *storeURL = [libraryURL URLByAppendingPathComponent:@"LocalFiles"];
        self.storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        
        if (![self.storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                 configuration:nil
                                                           URL:storeURL
                                                       options:nil
                                                         error:nil]) {
            NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"No store");
            return nil;
        }
        
        // Context
        self.managedObjectContext = [[NSManagedObjectContext alloc] init];
        [self.managedObjectContext setPersistentStoreCoordinator:self.storeCoordinator];
		
		for (LocalFileSource *source in self.localFileSources) {
			[source performUpdateScan];
			[source startFSEventStream];
		}
    }
	
	sharedInstance = self;
    return self;
}

@synthesize managedObjectModel;
@synthesize storeCoordinator;
@synthesize managedObjectContext;

#pragma mark -
#pragma mark Internal

-(void)commit {

    if (![self.managedObjectContext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![self.managedObjectContext save:nil]) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't save");
    }
}

#pragma mark -
#pragma mark API

-(NSArray *)localFileSources {
	NSFetchRequest *request = [self.managedObjectModel fetchRequestTemplateForName:@"AllSources"];
	return [self.managedObjectContext executeFetchRequest:request error:nil];
}

-(LocalFileSource *)addLocalFileSourceAtPath:(NSString *)path {
	
	if (path.length == 0) return nil;
	
	// First, look to see if we already have a source with this path.
	
	NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:path, @"TARGET_PATH",
							   nil];
	
	NSFetchRequest *request = [self.managedObjectModel fetchRequestFromTemplateWithName:@"SourceWithPath"
																  substitutionVariables:variables];
	request.entity = [NSEntityDescription entityForName:@"LocalFileSource"
								 inManagedObjectContext:self.managedObjectContext];
	NSError *error = nil;
	NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
	
	if (results.count > 0)
		return [results lastObject];
	
	// Nothing with the given path, make a new one.
	
	[self willChangeValueForKey:@"localFileSources"];
	
	LocalFileSource *source = (LocalFileSource *)[[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"LocalFileSource"
																									 inManagedObjectContext:self.managedObjectContext]
														  insertIntoManagedObjectContext:self.managedObjectContext];
	source.path = path;
	[source startFSEventStream];
	[self commit];
	
	[self didChangeValueForKey:@"localFileSources"];
	
	return source;
}

-(void)removeLocalFileSource:(LocalFileSource *)source {
	if (source == nil) return;
	[self willChangeValueForKey:@"localFileSources"];
	[source stopFSEventStream];
	[self.managedObjectContext deleteObject:source];
	[self commit];
	[self didChangeValueForKey:@"localFileSources"];
}

-(LocalFile *)localFileForTrack:(SPTrack *)track {
	
	if (track == nil) return nil;
	
	NSString *targetTitle = track.name;
	NSString *targetArtist = ((SPArtist *)track.artists.lastObject).name;
	NSString *targetAlbum = track.album.name;
	
	// Core Data + nil == bad.
	
	if (targetTitle == nil)
		targetTitle = @"";
	
	if (targetArtist == nil)
		targetArtist = @"";
	
	if (targetAlbum == nil)
		targetAlbum = @"";
	
	NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
							   targetTitle, @"TARGET_TITLE",
							   targetArtist, @"TARGET_ARTIST",
							   targetAlbum, @"TARGET_ALBUM",
							   nil];
	
	NSFetchRequest *request = [self.managedObjectModel fetchRequestFromTemplateWithName:@"LocalFileRequest"
																  substitutionVariables:variables];
	NSError *error = nil;
	NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
	
	return [results lastObject];
}

@end
