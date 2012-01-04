//
//  Constants.h
//  Viva
//
//  Created by Daniel Kennett on 3/27/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>

// ------ Playback ------

static NSUInteger const kShuffleHistoryLength = 1000;
// ^ The number of tracks to keep in shuffle history.
static NSTimeInterval const kSkipBackThreshold = 3.0;
// ^ If the "skip back" button is clicked after the track has been playing for this long, 
// the track will be restarted.
static NSTimeInterval const kNextTrackCacheThreshold = 5.0;
// ^ When we get this close to the end of a track, preload the next one.
static NSTimeInterval const kSeekABitInterval = 1.0;
static double const kVolumeStepSize = 0.1;
static NSString * const kMediaKeyUsingBundleIdentifiersDefaultsKey = @"kMediaKeyUsingBundleIdentifiersDefaultsKey";
static NSString * const kLoopPlaybackDefaultsKey = @"LoopPlayback";
static NSString * const kShufflePlaybackDefaultsKey = @"ShufflePlayback";

// ------ EQ ------

static NSString * const kUserEQPresetsUserDefaultsKey = @"UserEQPresets";
static NSString * const kUserUnnamedEQPresetUserDefaultsKey = @"UnnamedEQPreset";
static NSString * const kCurrentEQPresetNameUserDefaultsKey = @"EQPresetInUse";

// ------ Last.fm ------

static NSString * const kScrobblePlaybackToLastFMUserDefaultsKey = @"ScrobbleToLastFM";
static NSString * const kStarEqualsLastFMLoveUserDefaultsKey = @"StarEqualsLastFMLove";

// ------ Search ------

static NSUInteger const kLiveSearchMaximumResultsPerCategoryCount = 5;
static NSTimeInterval const kLiveSearchChangeInterval = 0.25; // Time between typing and a search starting.

// ------ Drag & Drop ------

static NSString * const kSpotifyTrackURLListDragIdentifier = @"com.spotify.Viva.TrackURLList";
static NSString * const kSpotifyTrackMoveSourceIndexSetDragIdentifier = @"com.spotify.Viva.TrackInPlaylistIndexSet";
// ^ The indexes in the source playlist rather than the current sort order.
static double const kDragImageMaximumMosaicSize = 64.0;

static NSString * const kSpotifyPlaylistMoveSourceDragIdentifier = @"com.spotify.Viva.PlaylistInParent";
static NSString * const kPlaylistURL = @"kPlaylistURL";
static NSString * const kPlaylistParentId = @"kPlaylistParentId";
static NSString * const kSpotifyFolderMoveSourceDragIdentifier = @"com.spotify.Viva.FolderInParent";
static NSString * const kFolderId = @"kFolderId";

// ------ Keychain ------

static NSString * const kVivaKeychainServiceName = @"Viva";
static NSString * const kVivaLibSpotifyUserAgentName = @"com.spotify.Viva";

// ------ User Defaults ------

static NSString * const kVivaLastUserNameUserDefaultsKey = @"LastUser";
static NSString * const kVivaMainViewHistoryUserDefaultsKey = @"History";

// ------ Notifications ------

static NSString * const kTrackShouldBePlayedNotification = @"kTrackShouldBePlayedNotification";
static NSString * const kPlaybackInitialTrackContainerKey = @"kPlaybackInitialTrackContainerKey";
