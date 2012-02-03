//
//  VivaLocalFileDecoder.m
//  Viva
//
//  Created by Daniel Kennett on 16/11/2011.
//  For license information, see LICENSE.markdown
//

#import "VivaLocalFileDecoder.h"
#import <AVFoundation/AVFoundation.h>
#import "LocalFilesController.h"
#import "VivaTrackExtensions.h"
#import "VivaAVAssetDecoderWorker.h"

@interface VivaLocalFileDecoder ()

@property (readwrite) BOOL cancelled;

@property (readwrite, strong) id <VivaLocalFileDecoderWorker> currentWorker;
@property (readwrite, strong) LocalFile *currentFile;

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
@synthesize currentFile;
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
	
	self.currentFile = localFile;
	self.currentWorker = [[VivaAVAssetDecoderWorker alloc] init];
	self.currentWorker.delegate = self;
	[self.currentWorker decodeLocalFile:self.currentFile fromPosition:0.0];
	self.currentWorker.playing = self.isPlaying;
	
	return YES;
}

-(void)seekPlaybackToOffset:(NSTimeInterval)offset {
	
	[self unloadPlayback];
	self.currentWorker = [[VivaAVAssetDecoderWorker alloc] init];
	self.currentWorker.delegate = self;
	
	// Fake audio delivery to get player to clear buffers.
	[self.playbackDelegate session:self shouldDeliverAudioFrames:NULL ofCount:0 format:NULL];
	
	[self.currentWorker decodeLocalFile:self.currentFile fromPosition:offset];
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

-(NSUInteger)worker:(VivaAVAssetDecoderWorker *)worker shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat {
	if (worker == self.currentWorker) {
		return [self.playbackDelegate session:nil
					 shouldDeliverAudioFrames:audioFrames
									  ofCount:frameCount
									   format:audioFormat];
	}
	return 0;
}

-(void)workerDidCompleteAudioPlayback:(VivaAVAssetDecoderWorker *)worker {
	if (worker == self.currentWorker) {
		[self unloadPlayback];
		[self.playbackDelegate sessionDidEndPlayback:self];
		
		if (worker == self.currentWorker || self.currentWorker == nil)
			self.playing = NO;
	}
}


@end
