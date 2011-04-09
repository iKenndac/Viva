//
//  VivaPlaybackContextViewController.h
//  Viva
//
//  Created by Daniel Kennett on 4/9/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaPlaybackContext.h"
#import "VivaInternalURLManager.h"

@interface VivaPlaybackContextViewController : NSViewController <VivaPlaybackContext, VivaViewController> {
@private
    NSArray *tracksForPlayback;
	NSURL *spotifyURL;
}

-(void)playTrackInThisContext:(SPSpotifyTrack *)track;

@end
