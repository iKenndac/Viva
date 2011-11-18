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
#import "VivaTrackExtensions.h"

@interface VivaLocalFileDecoder ()

@property (readwrite) BOOL cancelled;

@property (readwrite, strong) VivaLocalFileDecoderWorker *currentWorker;
@property (readwrite, strong) AVAsset *currentAsset;

@end

@implementation VivaLocalFileDecoder

-(id)init {
	
	self = [super init];
	
	if (self) {
		[self addObserver:self forKeyPath:@"playing" options:0 context:nil];
	}
	
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"playing"]) {
        self.currentWorker.playing = self.playing;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"playing"];
}

@synthesize playbackDelegate;
@synthesize cancelled;
@synthesize currentWorker;
@synthesize currentAsset;
@synthesize playing;

-(BOOL)preloadTrackForPlayback:(SPTrack *)aTrack error:(NSError **)error {
	// No-op for now.
	return NO;
}

-(BOOL)playTrack:(SPTrack *)aTrack error:(NSError **)error {
	
	LocalFile *localFile = aTrack.localFile;
	
	if (localFile == nil || ![[NSFileManager defaultManager] fileExistsAtPath:localFile.path]) {
		if (error)
			*error = [NSError errorWithDomain:@"com.spotify.Viva.LocalFileDecoder" code:67 userInfo:nil];
		return NO;
	}
	
	[self unloadPlayback];
	
	self.currentAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:localFile.path]];
	self.currentWorker = [[VivaLocalFileDecoderWorker alloc] init];
	self.currentWorker.delegate = self;
	[self.currentWorker decodeAsset:self.currentAsset fromPosition:0.0];
	self.playing = YES;
	
	return YES;
}

-(void)seekPlaybackToOffset:(NSTimeInterval)offset {
	
	[self unloadPlayback];
	self.currentWorker = [[VivaLocalFileDecoderWorker alloc] init];
	self.currentWorker.delegate = self;
	
	// Fake audio delivery to get player to clear buffers.
	[self.playbackDelegate session:self shouldDeliverAudioFrames:NULL ofCount:0 format:NULL];
	
	[self.currentWorker decodeAsset:self.currentAsset fromPosition:offset];
	self.currentWorker.playing = self.isPlaying;
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
		
		if (worker == self.currentWorker || self.currentWorker == nil)
			self.playing = NO;
	}
}


@end
