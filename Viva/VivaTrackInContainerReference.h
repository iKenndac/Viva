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

@interface VivaTrackInContainerReference : NSObject <VivaTrackContainer, NSCopying> {
@private
    NSString *uniqueId;
	__weak SPTrack *track;
	__weak id container;
}

-(id)initWithTrack:(SPTrack *)aTrack inContainer:(id)aContainer;

@property (copy, readonly) NSString *uniqueId;
@property (readonly) __weak SPTrack *track;
@property (readonly) __weak id container;

@end
