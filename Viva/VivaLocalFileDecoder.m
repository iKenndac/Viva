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
@property (readwrite) BOOL playbackThreadIsRunning;

@end

@implementation VivaLocalFileDecoder

@synthesize playing;
@synthesize playbackDelegate;
@synthesize cancelled;
@synthesize playbackThreadIsRunning;

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
	
	AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:localFile.path]];
	self.playbackThreadIsRunning = YES;
	self.playing = YES;
	[self performSelectorInBackground:@selector(decodeAsset:) withObject:asset];
	
	return YES;
}

-(void)seekPlaybackToOffset:(NSTimeInterval)offset {}

-(void)unloadPlayback {
	
	if (self.playbackThreadIsRunning)
		self.cancelled = YES;
}

#pragma mark -
#pragma mark Internal

-(void)decodeAsset:(AVAsset *)asset {
	
	@autoreleasepool {
		
		AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:nil];
		NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeAudio];
		AVAssetTrack *track = [tracks objectAtIndex:0];
		
		NSMutableDictionary* audioReadSettings = [NSMutableDictionary dictionary];
		[audioReadSettings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
		[audioReadSettings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
		[audioReadSettings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsNonInterleavedKey];
		[audioReadSettings setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
		[audioReadSettings setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
		
		AVAssetReaderTrackOutput *readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track
																							outputSettings:audioReadSettings];
		
		CMAudioFormatDescriptionRef format = (__bridge CMAudioFormatDescriptionRef)[[track formatDescriptions] objectAtIndex:0];
		const AudioStreamBasicDescription *audioFormat = CMAudioFormatDescriptionGetStreamBasicDescription(format);
		
		sp_audioformat outputFormat;
		outputFormat.channels = (int)audioFormat->mChannelsPerFrame;
		outputFormat.sample_type = SP_SAMPLETYPE_INT16_NATIVE_ENDIAN;
		outputFormat.sample_rate = (int)audioFormat->mSampleRate;
		
		[reader addOutput:readerOutput];
		[reader startReading];
		
		CMSampleBufferRef sample = [readerOutput copyNextSampleBuffer];
		
		while (sample != NULL && !self.cancelled) {
			
			CMBlockBufferRef buffer;
			AudioBufferList audioBufferList;
			CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sample,
																	NULL,
																	&audioBufferList,
																	sizeof(audioBufferList),
																	NULL,
																	NULL,
																	kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
																	&buffer);

			
			AudioBuffer audioBuffer = audioBufferList.mBuffers[0];
			UInt32 totalLength = audioBuffer.mDataByteSize;
			
			// Split up our huge-ass buffer into libspotify-sized ones for delivery.
			NSUInteger currentOffset = 0;
			NSUInteger chunkLength = 8192;
			
			while ((currentOffset < totalLength) && !self.cancelled) {
				
				NSUInteger thisChunkLength = (totalLength - currentOffset) < chunkLength ? (totalLength - currentOffset) : chunkLength;
				NSUInteger frameCount = thisChunkLength / (sizeof(sint16) * outputFormat.channels);
				
				while (([self.playbackDelegate session:nil
							 shouldDeliverAudioFrames:audioBuffer.mData + currentOffset
											  ofCount:frameCount
											   format:&outputFormat] == 0) && !self.cancelled) {
					[NSThread sleepForTimeInterval:0.3];
				}
				
				currentOffset += thisChunkLength;
			}
			
			CFRelease(buffer);
			CFRelease(sample);
			sample = [readerOutput copyNextSampleBuffer];
		}
	
		[self performSelectorOnMainThread:@selector(endPlaybackThread) withObject:nil waitUntilDone:NO];
	}
}

-(void)endPlaybackThread {
	
	BOOL wasCancelled = self.cancelled;
	
	self.playbackThreadIsRunning = NO;
	self.playing = NO;
	self.cancelled = NO;
	
	if (!wasCancelled)
		[self.playbackDelegate sessionDidEndPlayback:nil];
	
}


@end
