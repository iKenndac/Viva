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
    NSArray *trackContainersForPlayback;
	NSURL *spotifyURL;
	id <VivaTrackContainer> playingTrackContainer;
	BOOL playingTrackContainerIsCurrentlyPlaying;
}

-(void)playTrackContainerInThisContext:(id <VivaTrackContainer>)trackContainer;

@property (retain, readwrite) id <VivaTrackContainer> playingTrackContainer;
@property (readwrite) BOOL playingTrackContainerIsCurrentlyPlaying;

@end
