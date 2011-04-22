//
//  VivaPlayableTrack.m
//  Viva
//
//  Created by Daniel Kennett on 4/14/11.
//  Copyright 2011 Spotify. All rights reserved.
//

/*
 This is a very simple wrapper class that allows every single track in a context to be unique,
 whether they are or not. Needed to assist playback flow when a context has the same track(s)
 in it multiple times, and using indexes is stupid.
 */

#import "VivaTrackInContainerReference.h"

@interface VivaTrackInContainerReference ()

@property (copy, readwrite) NSString *uniqueId;
@property (assign, readwrite) __weak SPSpotifyTrack *track;
@property (assign, readwrite) __weak SPSpotifyPlaylist *container;

@end

@implementation VivaTrackInContainerReference

-(id)initWithTrack:(SPSpotifyTrack *)aTrack inContainer:(id)aContainer {
	if ((self = [super init])) {
		self.uniqueId = [[NSProcessInfo processInfo] globallyUniqueString];
		self.track = aTrack;
		self.container = aContainer;
	}
	return self;
}

@synthesize track;
@synthesize container;
@synthesize uniqueId;

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
	self.uniqueId = nil;
	self.track = nil;
	self.container = nil;
    [super dealloc];
}

@end
