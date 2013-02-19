//
//  PlaybackStatsController.m
//  Viva
//
//  Created by Daniel Kennett on 19/02/2013.
//  For license information, see LICENSE.markdown
//

#import "PlaybackStatsController.h"

@interface PlaybackStatsController ()

@property (nonatomic, readwrite, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readwrite, strong) NSPersistentStoreCoordinator *storeCoordinator;
@property (nonatomic, readwrite, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation PlaybackStatsController

-(id)init {
    self = [super init];

    if (self) {
        // Model
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PlaybackStats" withExtension:@"momd"];
        self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

        // Persistent Store
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *libraryURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
        libraryURL = [libraryURL URLByAppendingPathComponent:[[SPSession sharedSession] userAgent]];

        NSURL *storeURL = [libraryURL URLByAppendingPathComponent:@"PlaybackStats"];
        self.storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];

		NSError *error = nil;
        if (![self.storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                 configuration:nil
                                                           URL:storeURL
                                                       options:nil
                                                         error:&error]) {
            NSLog(@"[%@ %@]: No store: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
			// Error opening store, either because it's corrupt or we updated the model.
			// It's not important enough to migrate, so just delete it.
			[[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];

			if (![self.storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType
													 configuration:nil
															   URL:storeURL
														   options:nil
															 error:&error]) {

				NSLog(@"[%@ %@]: Failed again, giving up: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
				return nil;
			}
        }

        // Context
        self.managedObjectContext = [[NSManagedObjectContext alloc] init];
        [self.managedObjectContext setPersistentStoreCoordinator:self.storeCoordinator];
    }

    return self;
}

-(PlaybackStats *)playbackStatsForTrack:(SPTrack *)track {

    if (track == nil) return nil;

	// First, look to see if we already have a source with this path.

	NSDictionary *variables = @{ @"TARGET_URI" : track.spotifyURL.absoluteString };
	NSFetchRequest *request = [self.managedObjectModel fetchRequestFromTemplateWithName:@"StatsWithURI"
																  substitutionVariables:variables];
    
	request.entity = [NSEntityDescription entityForName:@"PlaybackStats"
								 inManagedObjectContext:self.managedObjectContext];
	NSError *error = nil;
	NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];

	if (results.count > 0)
		return [results lastObject];

	// Nothing with the given path, make a new one.
	PlaybackStats *stats = (PlaybackStats *)[[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:@"PlaybackStats"
                                                                                                inManagedObjectContext:self.managedObjectContext]
                                                     insertIntoManagedObjectContext:self.managedObjectContext];
	stats.trackURI = track.spotifyURL.absoluteString;
	[self commit];

	return stats;
}

-(void)reportSkipForTrack:(SPTrack *)track {

    if (track == nil) return;
    PlaybackStats *stats = [self playbackStatsForTrack:track];
    stats.skipCount++;
    // TODO: Change played dates?
    [self commit];
}

-(void)reportPlayForTrack:(SPTrack *)track {
    
    if (track == nil) return;
    PlaybackStats *stats = [self playbackStatsForTrack:track];

    NSDate *now = [NSDate date];
    stats.lastPlayed = now;
    if (stats.firstPlayed == nil) stats.firstPlayed = now;
    stats.playCount++;

    [self commit];
}

#pragma mark - Internal 

-(void)commit {

    if (![self.managedObjectContext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }

    if (![self.managedObjectContext save:nil]) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't save");
    }
}


@end
