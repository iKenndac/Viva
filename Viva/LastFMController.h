//
//  LastFMController.h
//  Viva
//
//  Created by Daniel Kennett on 14/11/2011.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

typedef enum {
	kLastFMDisconnected,
	kLastFMWaitingForAuth,
	kLastFMConnected
} LastFMConnectionState;

@interface LastFMController : NSObject 

+(LastFMController *)sharedInstance;

@property (readonly, nonatomic) LastFMConnectionState connectionState;
@property (readonly, copy, nonatomic) NSString *loggedInUser;

// --

-(IBAction)openManagementPage:(id)sender;
-(IBAction)disconnectFromLastFM:(id)sender;
-(IBAction)connectWithLastFM:(id)sender;

// --

-(void)notifyPlaybackDidStart:(SPTrack *)track;
-(void)notifyPlaybackDidPause:(SPTrack *)track;
-(void)notifyTrackPlaybackDidEnd:(SPTrack *)track atPosition:(NSTimeInterval)endPosition;
-(void)notifyLoveTrack:(SPTrack *)track;

@end
