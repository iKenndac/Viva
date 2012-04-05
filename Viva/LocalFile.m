//
//  LocalFile.m
//  Viva
//
//  Created by Daniel Kennett on 16/11/2011.
//  For license information, see LICENSE.markdown
//

#import "LocalFile.h"
#import "LocalFileSource.h"
#import "SPTrack+LocalFileExtensions.h"

static void * const kLocalFileInternalKVOContext = @"kLocalFileInternalKVOContext";

@interface LocalFile ()

-(NSString *)urlEncodedStringForString:(NSString *)plainOldString;

@end

@implementation LocalFile

-(id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context {
	self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
	
	if (self) {
		[self addObserver:self forKeyPath:@"album" options:0 context:kLocalFileInternalKVOContext];
		[self addObserver:self forKeyPath:@"artist" options:0 context:kLocalFileInternalKVOContext];
		[self addObserver:self forKeyPath:@"title" options:0 context:kLocalFileInternalKVOContext];
		[self addObserver:self forKeyPath:@"discNumber" options:0 context:kLocalFileInternalKVOContext];
		[self addObserver:self forKeyPath:@"trackNumber" options:0 context:kLocalFileInternalKVOContext];
	}
	
	return self;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"album"];
	[self removeObserver:self forKeyPath:@"artist"];
	[self removeObserver:self forKeyPath:@"title"];
	[self removeObserver:self forKeyPath:@"discNumber"];
	[self removeObserver:self forKeyPath:@"trackNumber"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == kLocalFileInternalKVOContext) {
		[self updateCachedTrack];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@dynamic album;
@dynamic artist;
@dynamic duration;
@dynamic path;
@dynamic title;
@dynamic source;
@synthesize trackNumber;
@synthesize discNumber;
@dynamic track;

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@", [super description], self.path];
}

+(NSSet *)keyPathsForValuesAffectingPath {
	return [NSSet setWithObjects:@"album", @"artist", @"title", @"duration", @"discNumber", @"trackNumber", nil];
}

-(void)updateCachedTrack {

	NSString *encodedArtist = [self urlEncodedStringForString:self.artist == nil ? @"" : self.artist];
	NSString *encodedTitle = [self urlEncodedStringForString:self.title == nil ? @"" : self.title];
	NSString *encodedAlbum = [self urlEncodedStringForString:self.album == nil ? @"" : self.album];
	
	NSString *localUrlString = [NSString stringWithFormat:@"spotify:local:%@:%@:%@:%ld",
								encodedArtist, encodedAlbum, encodedTitle, self.duration.integerValue];
	
	NSURL *url = [NSURL URLWithString:localUrlString];
	
	if ([self.track.spotifyURL isEqual:url]) 
		return;
	
	[SPTrack trackForTrackURL:url
					inSession:[SPSession sharedSession]
					 callback:^(SPTrack *aTrack) {
						 if (self.managedObjectContext == nil || self.isDeleted)
							 return;
							 
						 aTrack.localFile = self;
						 self.track = aTrack;
					 }];
}

-(NSString *)urlEncodedStringForString:(NSString *)plainOldString {
	NSString *encoded = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
																							  (__bridge CFStringRef)plainOldString,
																							  (CFStringRef)@" ",
																							  (CFStringRef)@"!*'\"();:@&=+$,/?%#[]%",
																							  kCFStringEncodingUTF8);
	return [encoded stringByReplacingOccurrencesOfString:@" " withString:@"+"];
}

@end
