//
//  VivaLocalFileDecoder.h
//  Viva
//
//  Created by Daniel Kennett on 16/11/2011.
//  For license information, see LICENSE.markdown
//

// This class is a libspotify-API compatible decoder for local files.
// It allows the class managing playback to implement it once and be
// able to play both Spotify-streamed and local tracks.

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaLocalFileDecoderWorker.h"
#import "VivaPlaybackProvider.h"

@interface VivaLocalFileDecoder : NSObject <VivaLocalFileDecoderWorkerDelegate, SPSessionPlaybackProvider, VivaPlaybackProvider>

///----------------------------
/// @name Audio Playback
///----------------------------

/** Returns `YES` if the session is currently playing a track, otherwise `NO`. */
@property (nonatomic, readwrite, getter=isPlaying) BOOL playing;

/** Returns the session's playback delegate object.
 
 The playback delegate is responsible for pushing raw audio data provided by the session
 to the system's audio output. See the SimplePlayback sample project for an example of how to do this.
 */
@property (nonatomic, weak) id <SPSessionPlaybackDelegate> playbackDelegate;

/** Preloads playback assets for the given track.
 
 For smooth changes between tracks, you can use this method to start loading track playback 
 data before the track needs to be played. The Spotify client does this a few seconds before moving 
 to the next track during normal playback.
 
 @param aTrack The track to preload.
 @param error An NSError pointer that will be filled with any error that occurs.
 @return Returns `YES` if loading started successfully, or `NO` if the track cannot be played.
 */
-(BOOL)preloadTrackForPlayback:(SPTrack *)aTrack error:(NSError **)error;

/** Start playing the given track.
 
 @param aTrack The track to play.
 @param error An NSError pointer that will be filled with any error that occurs.
 @return Returns `YES` if playback started successfully, or `NO` if the track cannot be played.
 */
-(BOOL)playTrack:(SPTrack *)aTrack error:(NSError **)error;

/** Seek the current playback position to the given time. 
 
 @param offset The time at which to seek to. Must be between 0.0 and the duration of the playing track.
 */
-(void)seekPlaybackToOffset:(NSTimeInterval)offset;

/** Unload playback resources from memory. 
 
 Call this when you're done playing to free up some memory. Called automatically on
 instance deallocation. 
 */
-(void)unloadPlayback;

@end
