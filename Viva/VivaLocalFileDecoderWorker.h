//
//  VivaLocalFileDecoderWorker.h
//  Viva
//
//  Created by Daniel Kennett on 16/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@class VivaLocalFileDecoderWorker;

@protocol VivaLocalFileDecoderWorkerDelegate <NSObject>

-(NSUInteger)worker:(VivaLocalFileDecoderWorker *)worker shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat;
-(void)workerDidCompleteAudioPlayback:(VivaLocalFileDecoderWorker *)worker;

@end

@interface VivaLocalFileDecoderWorker : NSObject

@property (nonatomic) __weak id <VivaLocalFileDecoderWorkerDelegate> delegate;
@property (readwrite) BOOL cancelled;
@property (readwrite, getter = isPlaying) BOOL playing;

-(void)decodeAsset:(AVAsset *)asset fromPosition:(NSTimeInterval)startTime;


@end
