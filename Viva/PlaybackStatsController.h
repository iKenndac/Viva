//
//  PlaybackStatsController.h
//  Viva
//
//  Created by Daniel Kennett on 19/02/2013.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "PlaybackStats.h"

@interface PlaybackStatsController : NSObject

-(PlaybackStats *)playbackStatsForTrack:(SPTrack *)track;

-(void)reportSkipForTrack:(SPTrack *)track;
-(void)reportPlayForTrack:(SPTrack *)track;

@end
