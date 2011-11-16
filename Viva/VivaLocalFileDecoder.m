//
//  VivaLocalFileDecoder.m
//  Viva
//
//  Created by Daniel Kennett on 16/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import "VivaLocalFileDecoder.h"
#import <AVFoundation/AVFoundation.h>
#import "LocalFilesController.h"

@interface VivaLocalFileDecoder ()

@property (readwrite) BOOL cancelled;

@property (readwrite, strong) VivaLocalFileDecoderWorker *currentWorker;
@property (readwrite, strong) AVAsset *currentAsset;

@end

@implementation VivaLocalFileDecoder

@synthesize playing;
@synthesize playbackDelegate;
@synthesize cancelled;
@synthesize currentWorker;
@synthesize currentAsset;

-(BOOL)preloadTrackForPlayback:(SPTrack *)aTrack error:(NSError **)error {
	// No-op for now.
	return NO;
}

-(BOOL)playTrack:(SPTrack *)aTrack error:(NSError **)error {
	
	LocalFile *localFile = [[LocalFilesController sharedInstance] localFileForTrack:aTrack];
	
	if (localFile == nil) {
		if (error)
			*error = [NSError errorWithDomain:@"com.spotify.Viva.LocalFileDecoder" code:67 userInfo:nil];
		return NO;
	}
	
	[self unloadPlayback];
	
	self.currentAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:localFile.path]];
	self.playing = YES;
	self.currentWorker = [[VivaLocalFileDecoderWorker alloc] init];
	self.currentWorker.delegate = self;
	[self.currentWorker decodeAsset:self.currentAsset fromPosition:0.0];
	
	return YES;
}

-(void)seekPlaybackToOffset:(NSTimeInterval)offset {
	
	[self unloadPlayback];
	self.currentWorker = [[VivaLocalFileDecoderWorker alloc] init];
	self.currentWorker.delegate = self;
	
	[self.playbackDelegate session:self shouldDeliverAudioFrames:NULL ofCount:0 format:NULL];
	[self.currentWorker decodeAsset:self.currentAsset fromPosition:offset];
}

-(void)unloadPlayback {
	if (self.currentWorker == nil) return;

	self.currentWorker.delegate = nil;
	self.currentWorker.cancelled = YES;
	self.currentWorker = nil;
}

#pragma mark -
#pragma mark Delegates

-(NSUInteger)worker:(VivaLocalFileDecoderWorker *)worker shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat {
	if (worker == self.currentWorker) {
		return [self.playbackDelegate session:nil
					 shouldDeliverAudioFrames:audioFrames
									  ofCount:frameCount
									   format:audioFormat];
	}
	return 0;
}

-(void)workerDidCompleteAudioPlayback:(VivaLocalFileDecoderWorker *)worker {
	if (worker == self.currentWorker) {
		[self unloadPlayback];
		[self.playbackDelegate sessionDidEndPlayback:self];
	}
}


@end
