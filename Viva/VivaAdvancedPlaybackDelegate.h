//
//  VivaAdvancedPlaybackDelegate.h
//  Viva
//
//  Created by Daniel Kennett on 03/02/2012.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import <CoreAudio/CoreAudio.h>

@protocol VivaAdvancedPlaybackDelegate <NSObject, SPSessionPlaybackDelegate>

-(NSInteger)session:(id <SPSessionPlaybackProvider>)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount audioStreamDescription:(AudioStreamBasicDescription)audioFormat;
-(void)sessionDidEndPlayback:(id<SPSessionPlaybackProvider>)aSession withError:(NSError *)anError;

@end
