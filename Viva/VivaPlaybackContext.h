//
//  VivaPlaybackContext.h
//  Viva
//
//  Created by Daniel Kennett on 3/30/11.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@protocol VivaTrackContainer <NSObject>

@property (readonly, weak) SPTrack *track;

@end

@protocol VivaPlaybackContext <NSObject>
@required

// This must be KVO compliant, for e.g. when the user filters the playlist
@property (readonly, nonatomic, retain) NSArray *trackContainersForPlayback;
@property (readonly, nonatomic, copy) NSURL *spotifyURL;

@optional
-(void)setPlayingTrackContainer:(id <VivaTrackContainer>)aTrackContainer isPlaying:(BOOL)playing;

@end
