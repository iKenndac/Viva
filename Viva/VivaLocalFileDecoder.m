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
#import "VivaFLACDecoderWorker.h"
#import "VivaAdvancedPlaybackDelegate.h"
#import "Constants.h"

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
@synthesize audioDeliveryDelegate;
@synthesize cancelled;
@synthesize currentWorker;
@synthesize currentFile;
@synthesize playing;

+(NSSet *)keyPathsForValuesAffectingDecoderStatistics {
	return [NSSet setWithObject:@"currentWorker.decoderStatistics"];
}

-(NSDictionary *)decoderStatistics {
	return self.currentWorker.decoderStatistics;
}

-(void)preloadTrackForPlayback:(SPTrack *)aTrack callback:(SPErrorableOperationCallback)block {
	// No-op for now.
	if (block) block(nil);
}

-(void)playTrack:(SPTrack *)aTrack callback:(SPErrorableOperationCallback)block {
	
	LocalFile *localFile = aTrack.localFile;
	
	if (localFile == nil || ![[NSFileManager defaultManager] fileExistsAtPath:localFile.path]) {
		if (block) block([NSError errorWithDomain:@"com.spotify.Viva.LocalFileDecoder"
											 code:kVivaTrackDecodingFailedErrorCode
										 userInfo:[NSDictionary dictionaryWithObject:@"Local file not found."
																			  forKey:NSLocalizedDescriptionKey]]);
		return;
	}
	
	[self unloadPlayback];
	
	Class decoderClass = [VivaAVAssetDecoderWorker class];
	if ([[localFile.path pathExtension] caseInsensitiveCompare:@"flac"] == NSOrderedSame) {
		decoderClass = [VivaFLACDecoderWorker class];
	}
	
	self.currentFile = localFile;
	self.currentWorker = [[decoderClass alloc] init];
	self.currentWorker.delegate = self;
	[self.currentWorker decodeLocalFile:self.currentFile fromPosition:0.0];
	self.currentWorker.playing = self.isPlaying;
	
	if (block) block(nil);
}

-(void)seekPlaybackToOffset:(NSTimeInterval)offset {
	
	Class replacementWorkerClass = [self.currentWorker class];
	
	[self unloadPlayback];
	self.currentWorker = [[replacementWorkerClass alloc] init];
	self.currentWorker.delegate = self;
	
	// Fake audio delivery to get player to clear buffers.
	AudioStreamBasicDescription blank;
	memset(&blank, 0, sizeof(blank));
	[self.audioDeliveryDelegate session:self shouldDeliverAudioFrames:NULL ofCount:0 streamDescription:blank];
	
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

-(NSUInteger)worker:(VivaAVAssetDecoderWorker *)worker shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(AudioStreamBasicDescription)audioFormat {
	if (worker == self.currentWorker) {
		
		return [self.audioDeliveryDelegate session:self
						  shouldDeliverAudioFrames:audioFrames
										   ofCount:frameCount
								 streamDescription:audioFormat];
	}
	return 0;
}

-(void)workerDidCompleteAudioPlayback:(VivaAVAssetDecoderWorker *)worker withError:(NSError *)anError {
	if (worker == self.currentWorker) {
		[self unloadPlayback];
		
		id <VivaAdvancedPlaybackDelegate> advancedPlaybackDelegate = (id <VivaAdvancedPlaybackDelegate>)self.playbackDelegate;
		[advancedPlaybackDelegate sessionDidEndPlayback:self withError:anError];
		
		if (worker == self.currentWorker || self.currentWorker == nil)
			self.playing = NO;
	}
}


@end
