//
//  VivaPlayableTrack.m
//  Viva
//
//  Created by Daniel Kennett on 4/14/11.
//  For license information, see LICENSE.markdown
//

/*
 This is a very simple wrapper class that allows every single track in a context to be unique,
 whether they are or not. Needed to assist playback flow when a context has the same track(s)
 in it multiple times, and using indexes is stupid.
 */

#import "VivaTrackInContainerReference.h"

@interface VivaTrackInContainerReference ()

@property (copy, readwrite) NSString *uniqueId;
@property (readwrite, weak) SPTrack *track;
@property (readwrite, weak) id container;
@property (readwrite, strong) SPPlaylistItem *playlistItem;

@end

@implementation VivaTrackInContainerReference

-(id)initWithTrack:(SPTrack *)aTrack inContainer:(id)aContainer {
	return [self initWithTrack:aTrack item:nil inContainer:aContainer];
}

-(id)initWithTrack:(SPTrack *)aTrack item:(SPPlaylistItem *)item inContainer:(id)aContainer {
	if ((self = [super init])) {
		self.uniqueId = [[NSProcessInfo processInfo] globallyUniqueString];
		self.track = aTrack;
		self.container = aContainer;
		self.playlistItem = item;
	}
	return self;
}

-(id)initWithTrack:(SPTrack *)aTrack item:(SPPlaylistItem *)item inContainer:(id)aContainer existingId:(NSString *)anId {
	if ((self = [super init])) {
		self.uniqueId = anId;
		self.track = aTrack;
		self.container = aContainer;
		self.playlistItem = item;
	}
	return self;
}


-(id)copyWithZone:(NSZone *)zone {
    return [[[self class] alloc] initWithTrack:self.track item:self.playlistItem inContainer:self.container existingId:self.uniqueId];
}

@synthesize track;
@synthesize container;
@synthesize uniqueId;
@synthesize playlistItem;

-(BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[VivaTrackInContainerReference class]]) {
		return [((VivaTrackInContainerReference *)object).uniqueId isEqualToString:self.uniqueId] && 
		((VivaTrackInContainerReference *)object).container == self.container && 
		((VivaTrackInContainerReference *)object).track == self.track;
	} else {
		return NO;
	}
}

- (void)dealloc {
	self.track = nil;
	self.container = nil;
	self.playlistItem = nil;
}

@end
