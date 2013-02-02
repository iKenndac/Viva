//
//  VivaPlaybackManager.h
//  Viva
//
//  Created by Daniel Kennett on 3/30/11.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import "VivaPlaybackContext.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import <Accelerate/Accelerate.h>
#import <CoreAudio/CoreAudio.h>
#import <AudioUnit/AudioUnit.h>
#import "EQPresetController.h"
#import "VivaAdvancedPlaybackDelegate.h"
#import "VivaCoreAudioController.h"

@class VivaPlaybackManager;

@protocol VivaPlaybackManagerDelegate <NSObject>

-(void)playbackManager:(VivaPlaybackManager *)manager didEncounterPlaybackError:(NSError *)error;

@end

@protocol VivaPlaybackManagerDataSource <NSObject>

-(BOOL)playbackManager:(VivaPlaybackManager *)manager requiresContextForContextlessPlayRequest:(id <VivaPlaybackContext> *)context;

@end

@interface VivaPlaybackManager : NSObject <SPSessionPlaybackDelegate, VivaAdvancedPlaybackDelegate, SPCoreAudioControllerDelegate>

-(id)initWithPlaybackSession:(SPSession *)aSession;

@property (readonly, strong, nonatomic) VivaCoreAudioController *audioController;
@property (readonly, strong, nonatomic) id <VivaPlaybackContext> playbackContext;
@property (readwrite, nonatomic) NSTimeInterval currentTrackPosition;
@property (readonly, strong, nonatomic) SPTrack *currentTrack;
@property (readonly, strong, nonatomic) id <VivaTrackContainer> currentTrackContainer;
@property (readonly, strong, nonatomic) SPSession *session;
@property (readonly, strong, nonatomic) id <SPSessionPlaybackProvider> currentPlaybackProvider;
@property (readwrite, nonatomic) BOOL loopPlayback;
@property (readwrite, nonatomic) BOOL shufflePlayback;

@property (readwrite, nonatomic, getter = isPlaying) BOOL playing;

-(NSString *)playPauseToggleMenuText;

@property (readonly, nonatomic) BOOL canSkipToNextTrack;
@property (readonly, nonatomic) BOOL canSkipToPreviousTrack;

@property (readwrite, assign, nonatomic) __unsafe_unretained id <VivaPlaybackManagerDataSource> dataSource;
@property (readwrite, nonatomic, assign) __unsafe_unretained id <VivaPlaybackManagerDelegate> delegate;

-(void)seekToTrackPosition:(NSTimeInterval)newPosition;

-(void)skipToNextTrackInCurrentContext:(BOOL)clearExistingAudioBuffers;
-(void)skipToPreviousTrackInCurrentContext:(BOOL)clearExistingAudioBuffers;

@end
