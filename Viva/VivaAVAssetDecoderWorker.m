//
//  VivaLocalFileDecoderWorker.m
//  Viva
//
//  Created by Daniel Kennett on 16/11/2011.
//  For license information, see LICENSE.markdown
//

#import "VivaAVAssetDecoderWorker.h"
#import <AVFoundation/AVFoundation.h>

@implementation VivaAVAssetDecoderWorker

@synthesize delegate;
@synthesize cancelled;
@synthesize playing;

-(void)decodeLocalFile:(LocalFile *)file fromPosition:(NSTimeInterval)startTime {
	
	AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:file.path]];
	
	[self performSelectorInBackground:@selector(decodeAssetOnThreadWithProperties:)
						   withObject:[NSDictionary dictionaryWithObjectsAndKeys:
									   asset, @"asset",
									   [NSNumber numberWithDouble:startTime], @"start", nil]];
	
}

-(void)decodeAssetOnThreadWithProperties:(NSDictionary *)properties {
	
	@autoreleasepool {
		
		AVAsset *asset = [properties valueForKey:@"asset"];
		NSTimeInterval startTime = [[properties valueForKey:@"start"] doubleValue];
		
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

		[reader setTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, audioFormat->mSampleRate), kCMTimePositiveInfinity)];
		[reader addOutput:readerOutput];
		[reader startReading];
		
		AudioStreamBasicDescription outputAudioFormat;
		outputAudioFormat.mSampleRate = audioFormat->mSampleRate;
		outputAudioFormat.mFormatID = kAudioFormatLinearPCM;
		outputAudioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked | kAudioFormatFlagsNativeEndian;
		outputAudioFormat.mBytesPerPacket = 2 /*channels*/ * sizeof(sint16);
		outputAudioFormat.mFramesPerPacket = 1;
		outputAudioFormat.mBytesPerFrame = outputAudioFormat.mBytesPerPacket;
		outputAudioFormat.mChannelsPerFrame = 2;
		outputAudioFormat.mBitsPerChannel = 16;
		outputAudioFormat.mReserved = 0;
		
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
				NSUInteger frameCount = thisChunkLength / outputAudioFormat.mBytesPerPacket;
				
				while (!self.isPlaying && !self.cancelled) {
					// Don't push audio data if we're paused.
					[NSThread sleepForTimeInterval:0.1];
				}
				
				while (!self.cancelled && ([self.delegate worker:self
										shouldDeliverAudioFrames:audioBuffer.mData + currentOffset
														 ofCount:frameCount
														  format:outputAudioFormat] == 0)) {
					[NSThread sleepForTimeInterval:0.3];
				}
				
				currentOffset += thisChunkLength;
			}
			
			CFRelease(buffer);
			CFRelease(sample);
			sample = NULL;
			sample = [readerOutput copyNextSampleBuffer];
		}
		
		if (sample != NULL)
			CFRelease(sample);
		
		
		[self performSelectorOnMainThread:@selector(endPlaybackThread) withObject:nil waitUntilDone:NO];
	}
}

-(void)endPlaybackThread {
	[self.delegate workerDidCompleteAudioPlayback:self];
}


@end
