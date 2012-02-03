//
//  VivaLocalFileDecoderWorker.h
//  Viva
//
//  Created by Daniel Kennett on 03/02/2012.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "LocalFile.h"

@protocol VivaLocalFileDecoderWorker;

@protocol VivaLocalFileDecoderWorkerDelegate <NSObject>

-(NSUInteger)worker:(id <VivaLocalFileDecoderWorker>)worker shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat;
-(void)workerDidCompleteAudioPlayback:(id <VivaLocalFileDecoderWorker>)worker;

@end

@protocol VivaLocalFileDecoderWorker <NSObject>

@property (nonatomic) __weak id <VivaLocalFileDecoderWorkerDelegate> delegate;
@property (readwrite) BOOL cancelled;
@property (readwrite, getter = isPlaying) BOOL playing;
-(void)decodeLocalFile:(LocalFile *)file fromPosition:(NSTimeInterval)startTime;


@end

