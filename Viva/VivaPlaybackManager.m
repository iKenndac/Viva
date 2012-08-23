//
//  VivaPlaybackManager.m
//  Viva
//
//  Created by Daniel Kennett on 3/30/11.
//  For license information, see LICENSE.markdown
//

#import "VivaPlaybackManager.h"
#import "Constants.h"
#import "SPArrayExtensions.h"
#import "LastFMController.h"
#import "LocalFilesController.h"
#import "VivaLocalFileDecoder.h"
#import "VivaTrackExtensions.h"
#import "SPSession+AudioStatistics.h"
#import <AudioToolbox/AudioToolbox.h>
#import <Growl/Growl.h>

@interface VivaPlaybackManager  ()

@property (readwrite, strong, nonatomic) EQCoreAudioController *audioController;
@property (strong, readwrite, nonatomic) id <VivaPlaybackContext> playbackContext;
@property (readwrite, strong, nonatomic) id <VivaTrackContainer> currentTrackContainer;
@property (readwrite, strong, nonatomic) SPSession *session;
@property (readwrite, strong, nonatomic) VivaLocalFileDecoder *localFileDecoder;
@property (readwrite, strong, nonatomic) id <SPSessionPlaybackProvider> currentPlaybackProvider;


-(void)playTrackContainerInCurrentContext:(id <VivaTrackContainer>)newTrack callback:(SPErrorableOperationCallback)block;

-(id <VivaTrackContainer>)nextTrackContainerInCurrentContext;
-(id <VivaTrackContainer>)previousTrackContainerInCurrentContext;

// Shuffle

-(void)addTrackContainerToPastShuffleHistory:(id <VivaTrackContainer>)container;
-(void)addTrackContainerToFutureShuffleHistory:(id <VivaTrackContainer>)container;
-(void)resetShuffledPool;
-(void)resetShuffleHistory;
-(id <VivaTrackContainer>)randomAvailableTrackContainerInCurrentContext;
-(void)addTrackContainerToShufflePool:(id <VivaTrackContainer>)track;

// Last.fm

-(void)scrobbleTrackStopped:(SPTrack *)track atPosition:(NSTimeInterval)position;

@end

@implementation VivaPlaybackManager {
	
	BOOL hasPreCachedNextTrack;
	NSMethodSignature *incrementTrackPositionMethodSignature;
	NSInvocation *incrementTrackPositionInvocation;
	
    NSMutableArray *shuffledPool;
    NSMutableArray *shufflePastHistory;
    NSMutableArray *shuffleFutureHistory;
    
	// Data from libSpotify only
	AudioStreamBasicDescription libSpotifyInputFormat;
	
	BOOL _playing;
}

- (id)initWithPlaybackSession:(SPSession *)aSession {
    self = [super init];
    if (self) {
        // Initialization code here.
        
        shuffledPool = [NSMutableArray new];
        shufflePastHistory = [[NSMutableArray alloc] initWithCapacity:kShuffleHistoryLength];
        shuffleFutureHistory = [[NSMutableArray alloc] initWithCapacity:kShuffleHistoryLength];
		
		self.audioController = [[EQCoreAudioController alloc] init];
		self.audioController.delegate = self;
		
		self.session = aSession;
		self.session.playbackDelegate = self;
		self.localFileDecoder = [[VivaLocalFileDecoder alloc] init];
		self.localFileDecoder.playbackDelegate = self;
		
        self.loopPlayback = [[NSUserDefaults standardUserDefaults] boolForKey:kLoopPlaybackDefaultsKey];
        self.shufflePlayback = [[NSUserDefaults standardUserDefaults] boolForKey:kShufflePlaybackDefaultsKey];
        		
        [self addObserver:self
               forKeyPath:@"playing"
                  options:0
                  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"currentTrackContainer"
				  options:NSKeyValueObservingOptionOld
				  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"currentTrackPosition"
				  options:0
				  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"playbackContext"
				  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
				  context:nil];
		
        [self addObserver:self
               forKeyPath:@"loopPlayback"
                  options:0
                  context:nil];

        [self addObserver:self
               forKeyPath:@"shufflePlayback"
                  options:0
                  context:nil];

		// Playback
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(playTrackFromUserAction:)
													 name:kTrackShouldBePlayedNotification
												   object:nil];
    }
    
    return self;
}

@synthesize audioController;
@synthesize playbackContext;
@synthesize currentTrackContainer;
@synthesize session;
@synthesize currentPlaybackProvider;
@synthesize currentTrackPosition;
@synthesize loopPlayback;
@synthesize shufflePlayback;
@synthesize dataSource;
@synthesize localFileDecoder;
@synthesize delegate;

-(void)setPlaying:(BOOL)playing {
	_playing = playing;
	self.currentPlaybackProvider.playing = playing;
	self.audioController.audioOutputEnabled = _playing;
}

-(BOOL)isPlaying {
	return _playing && self.currentPlaybackProvider.playing;
}

+(NSSet *)keyPathsForValuesAffectingCurrentTrack {
	return [NSSet setWithObjects:@"currentTrackContainer.track", nil];
}

-(SPTrack *)currentTrack {
	return self.currentTrackContainer.track;
}

+(NSSet *)keyPathsForValuesAffectingCanSkipToNextTrack {
	return [NSSet setWithObjects:@"loopPlayback", @"currentTrack", @"playbackContext.trackContainersForPlayback", nil];
}

-(BOOL)canSkipToNextTrack {
	return (self.loopPlayback || 
			[self.playbackContext.trackContainersForPlayback indexOfObject:self.currentTrackContainer] != [self.playbackContext.trackContainersForPlayback count] - 1);			
}

+(NSSet *)keyPathsForValuesAffectingCanSkipToPreviousTrack {
	return [NSSet setWithObjects:@"loopPlayback", @"currentTrack", @"playbackContext.trackContainersForPlayback", nil];
}

-(BOOL)canSkipToPreviousTrack {
	return (self.loopPlayback || 
			[self.playbackContext.trackContainersForPlayback indexOfObject:self.currentTrack] != 0);			
}

+(NSSet *)keyPathsForValuesAffectingPlayPauseToggleMenuText {
	return [NSSet setWithObject:@"playing"];
}

-(NSString *)playPauseToggleMenuText {
	return self.isPlaying ? @"Pause" : @"Play";
}

#pragma mark -
#pragma mark Playback Control

-(void)playTrackFromUserAction:(NSNotification *)aNotification {
	
	if (self.currentTrackContainer != nil)
		[self scrobbleTrackStopped:self.currentTrackContainer.track atPosition:self.currentTrackPosition];
	
	// User double-clicked, so reset everything and start again.
	self.playing = NO;
    self.currentTrackContainer = nil;
	[self.currentPlaybackProvider unloadPlayback];
	[self resetShuffledPool];
	[self.audioController clearAudioBuffers];
    
	if (![[aNotification object] conformsToProtocol:@protocol(VivaPlaybackContext)]) {
        id <VivaPlaybackContext> context = nil;
        
        if (![self.dataSource playbackManager:self requiresContextForContextlessPlayRequest:&context] || context == nil)
            return;
        
        self.playbackContext = context;
    } else {
        self.playbackContext = [aNotification object];
    }
    
	id <VivaTrackContainer> container = [[aNotification userInfo] valueForKey:kPlaybackInitialTrackContainerKey];
    
    if (container == nil)
        container = [self nextTrackContainerInCurrentContext];
    
    if (container == nil && self.playbackContext.trackContainersForPlayback.count > 0) {
        
        for (NSUInteger containerIndex = 0; containerIndex < self.playbackContext.trackContainersForPlayback.count; containerIndex++) {
            id <VivaTrackContainer> potentialContainer = [self.playbackContext.trackContainersForPlayback objectAtIndex:containerIndex];
            if (potentialContainer.track.availability == SP_TRACK_AVAILABILITY_AVAILABLE || potentialContainer.track.localFile != nil) {
                container = potentialContainer;
                break;
            }
        }
    }
    
	if (container == nil) {
		[self bailOutOfAudioPlaybackWithError:nil fromTrackContainer:nil informDelegate:YES];
		return;
	}
	
    [self playTrackContainerInCurrentContext:container callback:^(NSError *error) {
		if (error)
			[self bailOutOfAudioPlaybackWithError:error fromTrackContainer:container informDelegate:YES];
		else
			self.playing = YES;
	}];
}

-(void)playTrackContainerInCurrentContext:(id <VivaTrackContainer>)newTrack callback:(SPErrorableOperationCallback)block {
	
	// Don't clear out the audio buffer just in case we can manage gapless playback.
    self.currentTrackPosition = 0.0;
	
	self.currentPlaybackProvider.audioDeliveryDelegate = nil;
    self.currentPlaybackProvider.playing = NO;
	
	if (newTrack.track.localFile != nil) {
		self.currentPlaybackProvider = self.localFileDecoder;
	} else {
		self.currentPlaybackProvider = self.session;
	}
	
	self.currentPlaybackProvider.audioDeliveryDelegate = self.audioController;
	
	[self.currentPlaybackProvider playTrack:newTrack.track callback:^(NSError *error) {
		
		if (error == nil) {
			if (self.shufflePlayback)
				[self addTrackContainerToShufflePool:currentTrackContainer];
			
			self.currentTrackContainer = newTrack;
			self.playing = YES;
			
			[self reportTrackToGrowl:self.currentTrack];
			
		} else {
			self.playing = NO;
			[self.audioController clearAudioBuffers];
		}
		
		if (block) block(error);
	}];
}
	
-(void)seekToTrackPosition:(NSTimeInterval)newPosition {
	if (newPosition <= self.currentTrack.duration) {
		[self.currentPlaybackProvider seekPlaybackToOffset:newPosition];
		self.currentTrackPosition = newPosition;
	}	
}

-(id <VivaTrackContainer>)nextTrackContainerInCurrentContext {
    
    if (self.shufflePlayback) {
        id <VivaTrackContainer> track = nil;
        
        if (shuffleFutureHistory.count > 0) {
            track = [shuffleFutureHistory lastObject];
            [shuffleFutureHistory removeLastObject];
        } else {
            track = [self randomAvailableTrackContainerInCurrentContext];
        }
        
        if (track == nil && self.loopPlayback) {
            [self resetShuffledPool];
            track = [self randomAvailableTrackContainerInCurrentContext];
        }
        return track;
    }
	
	NSUInteger currentTrackIndex = [self.playbackContext.trackContainersForPlayback indexOfObject:self.currentTrackContainer];
	
	if (currentTrackIndex == NSNotFound ||
		(currentTrackIndex == [self.playbackContext.trackContainersForPlayback count] - 1 && !self.loopPlayback)) {
		return nil;
        
	} else {
		
        NSInteger newTrackIndex = 0;
        
        if (currentTrackIndex != [self.playbackContext.trackContainersForPlayback count] - 1)
            newTrackIndex = currentTrackIndex + 1;
        
        id <VivaTrackContainer> nextTrack = [self.playbackContext.trackContainersForPlayback objectAtIndex:newTrackIndex];
        
        while (nextTrack.track.availability != SP_TRACK_AVAILABILITY_AVAILABLE && nextTrack.track.localFile == nil) {
            
            newTrackIndex++;
            if (newTrackIndex >= self.playbackContext.trackContainersForPlayback.count) {
                nextTrack = nil;
                break;
            }
            nextTrack = [self.playbackContext.trackContainersForPlayback objectAtIndex:newTrackIndex];
        }
        return nextTrack;
	}
}

-(void)skipToNextTrackInCurrentContext:(BOOL)clearExistingAudioBuffers {
	
	if (self.currentTrackContainer != nil)
		[self scrobbleTrackStopped:self.currentTrackContainer.track atPosition:self.currentTrackPosition];
	
	BOOL wasPlaying = _playing;
	
	if (clearExistingAudioBuffers) {
		self.currentPlaybackProvider.playing = NO;
		[self.currentPlaybackProvider unloadPlayback];
		[self.audioController clearAudioBuffers];
	}
	
	id <VivaTrackContainer> nextContainer = [self nextTrackContainerInCurrentContext];
	
    if (self.shufflePlayback && self.currentTrackContainer != nil)
        [self addTrackContainerToPastShuffleHistory:self.currentTrackContainer];
    
	if (nextContainer == nil) {
		[self bailOutOfAudioPlaybackWithError:nil fromTrackContainer:nil informDelegate:NO];
		return;
	}
	
	[self playTrackContainerInCurrentContext:nextContainer callback:^(NSError *error) {
		if (error)
			[self bailOutOfAudioPlaybackWithError:error fromTrackContainer:nextContainer informDelegate:NO];
		else
			self.playing = wasPlaying;
	}];
}

-(id <VivaTrackContainer>)previousTrackContainerInCurrentContext {
	
    if (self.shufflePlayback) {
        id <VivaTrackContainer> track = nil;
        
        if (shufflePastHistory.count > 0) {
            track = [shufflePastHistory lastObject];
            [shufflePastHistory removeLastObject];
        } else {
            track = [self randomAvailableTrackContainerInCurrentContext];
        }
        
        if (track == nil && self.loopPlayback) {
            [self resetShuffledPool];
            track = [self randomAvailableTrackContainerInCurrentContext];
        }
        return track;
    }

    
	NSUInteger currentTrackIndex = [self.playbackContext.trackContainersForPlayback indexOfObject:self.currentTrackContainer];
	
	if (currentTrackIndex == NSNotFound ||
		(currentTrackIndex == 0 && !self.loopPlayback)) {
		return nil;
        
        
    } else {
        
        NSInteger newTrackIndex = [self.playbackContext.trackContainersForPlayback count] - 1;
        
        if (currentTrackIndex != 0)
            newTrackIndex = currentTrackIndex - 1;
        
        id <VivaTrackContainer> previousTrack = [self.playbackContext.trackContainersForPlayback objectAtIndex:newTrackIndex];
        
        while (previousTrack.track.availability != SP_TRACK_AVAILABILITY_AVAILABLE && previousTrack.track.localFile == nil) {
            
            newTrackIndex--;
            if (newTrackIndex < 0) {
                previousTrack = nil;
                break;
            }
            previousTrack = [self.playbackContext.trackContainersForPlayback objectAtIndex:newTrackIndex];
        }
        return previousTrack;
    }
}

-(void)skipToPreviousTrackInCurrentContext:(BOOL)clearExistingAudioBuffers {
	
	if (self.currentTrackContainer != nil)
		[self scrobbleTrackStopped:self.currentTrackContainer.track atPosition:self.currentTrackPosition];
	
	BOOL wasPlaying = _playing;
	
	if (clearExistingAudioBuffers) {
		self.currentPlaybackProvider.playing = NO;
		[self.currentPlaybackProvider unloadPlayback];
		[self.audioController clearAudioBuffers];
	}
	
	id <VivaTrackContainer> previousContainer = [self previousTrackContainerInCurrentContext];
	
    if (self.shufflePlayback && self.currentTrackContainer != nil)
        [self addTrackContainerToFutureShuffleHistory:self.currentTrackContainer];

	if (previousContainer == nil) {
		[self bailOutOfAudioPlaybackWithError:nil fromTrackContainer:nil informDelegate:NO];
		return;
	}
	
	[self playTrackContainerInCurrentContext:previousContainer callback:^(NSError *error) {
		if (error)
			[self bailOutOfAudioPlaybackWithError:error fromTrackContainer:previousContainer informDelegate:NO];
		else
			self.playing = wasPlaying;
	}];
}

-(void)bailOutOfAudioPlaybackWithError:(NSError *)error fromTrackContainer:(id <VivaTrackContainer>)container informDelegate:(BOOL)informDelegate {
	
	self.currentTrackContainer = nil;
	self.playing = NO;
	self.audioController.audioOutputEnabled = NO;
	[self.audioController clearAudioBuffers];
	self.currentTrackPosition = 0;
	
	if (error)
		NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
	
	if (informDelegate) {
		NSMutableDictionary *errorDict = [NSMutableDictionary dictionary];
		[errorDict setValue:container forKey:kVivaTrackContainerKey];
		if (error) [errorDict setValue:error forKey:NSUnderlyingErrorKey];
		
		[self.delegate playbackManager:self didEncounterPlaybackError:[NSError errorWithDomain:kVivaPlaybackManagerErrorDomain
																						  code:kVivaTrackFailedToPlayErrorCode
																					  userInfo:errorDict]];
	}
	
}

#pragma mark -
#pragma mark Managing Shuffle

-(void)addTrackContainerToPastShuffleHistory:(id <VivaTrackContainer>)container {
    if (!container) return;
    if (shufflePastHistory.count >= kShuffleHistoryLength)
        [shufflePastHistory removeObjectAtIndex:0];
    
    [shufflePastHistory addObject:container];
}

-(void)addTrackContainerToFutureShuffleHistory:(id <VivaTrackContainer>)container {
    if (!container) return;
    if (shuffleFutureHistory.count >= kShuffleHistoryLength)
        [shuffleFutureHistory removeObjectAtIndex:0];
    
    [shuffleFutureHistory addObject:container];
}

-(void)resetShuffledPool {
    [shuffledPool removeAllObjects];
}

-(void)resetShuffleHistory {
    [shuffleFutureHistory removeAllObjects];
    [shufflePastHistory removeAllObjects];
}

-(id <VivaTrackContainer>)randomAvailableTrackContainerInCurrentContext {
    
    NSMutableArray *tracks = [[[self playbackContext] trackContainersForPlayback] mutableCopy];
    [tracks removeObjectsInArray:shuffledPool];
    
    NSMutableArray *unavailableTracks = [NSMutableArray array];
    
    for (id <VivaTrackContainer> trackContainer in tracks) {
        if (trackContainer.track.availability != SP_TRACK_AVAILABILITY_AVAILABLE &&
			trackContainer.track.localFile == nil) {
            [unavailableTracks addObject:trackContainer];
			// If a track isn't available, pretend we've played it so we don't have to check the track
			// every time.
			[self addTrackContainerToShufflePool:trackContainer];
		}
    }
    
    [tracks removeObjectsInArray:unavailableTracks];

    if (tracks.count == 0)
        return nil;
    
    id <VivaTrackContainer> trackContainer = [tracks randomObject];
    [self addTrackContainerToShufflePool:trackContainer];
    return trackContainer;
}

-(void)addTrackContainerToShufflePool:(id <VivaTrackContainer>)track {
    if (!track) return;
    [shuffledPool addObject:track];
}

#pragma mark -
#pragma mark Last.fm

-(void)scrobbleTrackStopped:(SPTrack *)track atPosition:(NSTimeInterval)position {
	if (track != nil && [[NSUserDefaults standardUserDefaults] boolForKey:kScrobblePlaybackToLastFMUserDefaultsKey])
		[[LastFMController sharedInstance] notifyTrackPlaybackDidEnd:track atPosition:position];	
}

-(void)reportTrackToGrowl:(SPTrack *)track {
	
	void (^postNotification)() = ^(NSArray *imageOrAlbum, NSArray *notLoadedImageOrAlbum) {
		
		[GrowlApplicationBridge notifyWithTitle:track.name
									description:[NSString stringWithFormat:@"%@\n%@", track.consolidatedArtists, track.album.name]
							   notificationName:kGrowlNotificationNameNewTrack
									   iconData:[track.album.cover.image TIFFRepresentation]
									   priority:0
									   isSticky:NO
								   clickContext:nil
									 identifier:@"com.spotify.Viva.trackChanged"];
	};

	[SPAsyncLoading waitUntilLoaded:track timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *trackArray, NSArray *notLoadedTracks) {
		[SPAsyncLoading waitUntilLoaded:[track.artists arrayByAddingObject:track.album] timeout:kSPAsyncLoadingDefaultTimeout then:^(NSArray *albumAndArtists, NSArray *notLoadedAlbumAndArtists) {
			
			if (track.album.cover == nil)
				postNotification([NSArray arrayWithObject:track.album]);
			else
				[SPAsyncLoading waitUntilLoaded:track.album.cover timeout:kSPAsyncLoadingDefaultTimeout then:postNotification];
		}];
	}];
}

#pragma mark -
#pragma mark Playback Callbacks

-(void)sessionDidLosePlayToken:(id <SPSessionPlaybackProvider>)aSession {
	[self.delegate playbackManager:self
		 didEncounterPlaybackError:[NSError errorWithDomain:kVivaPlaybackManagerErrorDomain
													   code:kVivaTrackTokenLostErrorCode
												   userInfo:nil]];
	
	self.playing = NO;
}

-(void)sessionDidEndPlayback:(id <SPSessionPlaybackProvider>)aSession withError:(NSError *)anError {
	
	if (anError) {
		NSMutableDictionary *errorMutableDict = [NSMutableDictionary dictionaryWithDictionary:anError.userInfo];
		[errorMutableDict setValue:self.currentTrackContainer forKey:kVivaTrackContainerKey];
		
		[self.delegate playbackManager:self didEncounterPlaybackError:[NSError errorWithDomain:anError.domain
																						  code:anError.code
																					  userInfo:errorMutableDict]];
	}
	
	[self sessionDidEndPlayback:aSession];
}

-(void)sessionDidEndPlayback:(id <SPSessionPlaybackProvider>)aSession {
	// Not routing this through to the main thread causes odd locks and crashes.
	[self performSelectorOnMainThread:@selector(sessionDidEndPlaybackOnMainThread:)
						   withObject:aSession
						waitUntilDone:YES];
}

-(void)sessionDidEndPlaybackOnMainThread:(id <SPSessionPlaybackProvider>)aSession {
	[self skipToNextTrackInCurrentContext:NO];
}

#pragma mark -
#pragma mark Delegates and KVO

-(void)coreAudioController:(SPCoreAudioController *)controller didOutputAudioOfDuration:(NSTimeInterval)audioDuration {
	self.currentTrackPosition += audioDuration;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
	if ([keyPath isEqualToString:@"playing"]) {
		
		if (self.currentTrackContainer != nil && [[NSUserDefaults standardUserDefaults] boolForKey:kScrobblePlaybackToLastFMUserDefaultsKey]) {
			if (self.playing)
				[[LastFMController sharedInstance] notifyPlaybackDidStart:self.currentTrackContainer.track];
			else
				[[LastFMController sharedInstance] notifyPlaybackDidPause:self.currentTrackContainer.track];
		}
		
		if ([self.playbackContext respondsToSelector:@selector(setPlayingTrackContainer:isPlaying:)]) {
			[self.playbackContext setPlayingTrackContainer:self.currentTrackContainer isPlaying:self.currentPlaybackProvider.isPlaying];
		}
		
	} else if ([keyPath isEqualToString:@"currentTrackContainer"]) {
		@synchronized(self) {
			hasPreCachedNextTrack = NO;
		}
		
		if ([self.playbackContext respondsToSelector:@selector(setPlayingTrackContainer:isPlaying:)]) {
			[self.playbackContext setPlayingTrackContainer:self.currentTrackContainer isPlaying:self.currentPlaybackProvider.isPlaying];
		}
		
	} else if ([keyPath isEqualToString:@"playbackContext"]) {
		
		id oldContext = [change valueForKey:NSKeyValueChangeOldKey];
		if (oldContext != nil && oldContext != [NSNull null]) {
			if ([oldContext respondsToSelector:@selector(setPlayingTrackContainer:isPlaying:)]) {
				[oldContext setPlayingTrackContainer:nil isPlaying:NO];
			}
		}
		
		id newContext = [change valueForKey:NSKeyValueChangeNewKey];
		if (newContext != nil && newContext != [NSNull null]) {
			if ([newContext respondsToSelector:@selector(setPlayingTrackContainer:isPlaying:)]) {
				[newContext setPlayingTrackContainer:self.currentTrackContainer isPlaying:self.currentPlaybackProvider.isPlaying];
			}
		}
		
	} else if ([keyPath isEqualToString:@"currentTrackPosition"]) {
		if (!hasPreCachedNextTrack && self.currentTrack.duration - self.currentTrackPosition <= kNextTrackCacheThreshold) {
			id <VivaTrackContainer> nextContainer = [self nextTrackContainerInCurrentContext];
			if (nextContainer != nil) {
				[self.currentPlaybackProvider preloadTrackForPlayback:nextContainer.track callback:nil];
				@synchronized(self) {
					hasPreCachedNextTrack = YES;
				}
			}
		}
        
    } else if ([keyPath isEqualToString:@"loopPlayback"]) {
        [[NSUserDefaults standardUserDefaults] setBool:self.loopPlayback forKey:kLoopPlaybackDefaultsKey];
        
    } else if ([keyPath isEqualToString:@"shufflePlayback"]) {
        [[NSUserDefaults standardUserDefaults] setBool:self.shufflePlayback forKey:kShufflePlaybackDefaultsKey];
        [self resetShuffledPool];
        if (self.shufflePlayback)
            [self addTrackContainerToShufflePool:self.currentTrackContainer];
        else
            [self resetShuffleHistory];
            
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -

-(void)dealloc {

    [self removeObserver:self forKeyPath:@"playing"];
	[self removeObserver:self forKeyPath:@"currentTrackContainer"];
	[self removeObserver:self forKeyPath:@"currentTrackPosition"];
	[self removeObserver:self forKeyPath:@"playbackContext"];
    [self removeObserver:self forKeyPath:@"loopPlayback"];
    [self removeObserver:self forKeyPath:@"shufflePlayback"];
}

@end
