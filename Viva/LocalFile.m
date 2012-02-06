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

@implementation LocalFile {
	SPTrack *cachedTrack;
}

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
        cachedTrack = nil;
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

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@", [super description], self.path];
}

+(NSSet *)keyPathsForValuesAffectingPath {
	return [NSSet setWithObjects:@"album", @"artist", @"title", @"duration", @"discNumber", @"trackNumber", nil];
}

-(SPTrack *)track {
	
	if (cachedTrack == nil) {
		NSString *encodedArtist = [self urlEncodedStringForString:self.artist == nil ? @"" : self.artist];
		NSString *encodedTitle = [self urlEncodedStringForString:self.title == nil ? @"" : self.title];
		NSString *encodedAlbum = [self urlEncodedStringForString:self.album == nil ? @"" : self.album];
		
		NSString *localUrlString = [NSString stringWithFormat:@"spotify:local:%@:%@:%@:%u",
									encodedArtist, encodedAlbum, encodedTitle, self.duration.integerValue];
		
		cachedTrack = [SPTrack trackForTrackURL:[NSURL URLWithString:localUrlString] inSession:[SPSession sharedSession]];
		cachedTrack.localFile = self;
	}
	
	return cachedTrack;
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
