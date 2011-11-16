//
//  VivaLocalFileDecoderWorker.m
//  Viva
//
//  Created by Daniel Kennett on 16/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import "VivaLocalFileDecoderWorker.h"

@implementation VivaLocalFileDecoderWorker

@synthesize delegate;
@synthesize cancelled;
@synthesize playing;

-(void)decodeAsset:(AVAsset *)asset fromPosition:(NSTimeInterval)startTime {
	
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
		
		sp_audioformat outputFormat;
		outputFormat.channels = (int)audioFormat->mChannelsPerFrame;
		outputFormat.sample_type = SP_SAMPLETYPE_INT16_NATIVE_ENDIAN;
		outputFormat.sample_rate = (int)audioFormat->mSampleRate;
		
		[reader setTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, outputFormat.sample_rate), kCMTimePositiveInfinity)];
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
				
				while (([self.delegate worker:self
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
	[self.delegate workerDidCompleteAudioPlayback:self];
}


@end
