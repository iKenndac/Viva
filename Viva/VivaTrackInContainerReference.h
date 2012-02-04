//
//  VivaPlayableTrack.h
//  Viva
//
//  Created by Daniel Kennett on 4/14/11.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaPlaybackContext.h"

@interface VivaTrackInContainerReference : NSObject <VivaTrackContainer, NSCopying>

-(id)initWithTrack:(SPTrack *)aTrack inContainer:(id)aContainer;

@property (copy, readonly) NSString *uniqueId;
@property (readonly, weak) SPTrack *track;
@property (readonly, weak) id container;

@end
