//
//  VivaPlayableTrack.h
//  Viva
//
//  Created by Daniel Kennett on 4/14/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaPlaybackContext.h"

@interface VivaTrackInContainerReference : NSObject <VivaTrackContainer> {
@private
    NSString *uniqueId;
	__weak SPSpotifyTrack *track;
	__weak id container;
}

-(id)initWithTrack:(SPSpotifyTrack *)aTrack inContainer:(id)aContainer;

@property (copy, readonly) NSString *uniqueId;
@property (assign, readonly) __weak SPSpotifyTrack *track;
@property (assign, readonly) __weak id container;

@end
