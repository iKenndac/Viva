//
//  VivaFLACDecoder.m
//  Viva
//
//  Created by Daniel Kennett on 03/02/2012.
//  For license information, see LICENSE.markdown
//

#import "VivaFLACDecoderWorker.h"
#import "stream_decoder.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "Constants.h"

static FLAC__StreamDecoderWriteStatus FLAC_write_callback(const FLAC__StreamDecoder *decoder, const FLAC__Frame *frame, const FLAC__int32 * const buffer[], void *client_data);
static void FLAC_metadata_callback(const FLAC__StreamDecoder *decoder, const FLAC__StreamMetadata *metadata, void *client_data);
static void FLAC_error_callback(const FLAC__StreamDecoder *decoder, FLAC__StreamDecoderErrorStatus status, void *client_data);

@implementation VivaFLACDecoderWorker {
	FLAC__uint64 total_samples;
	NSUInteger sample_rate;
	NSUInteger channels;
	NSUInteger bits_per_sample;
	AudioStreamBasicDescription output_format;
	NSError *decodingError;
}

@synthesize delegate;
@synthesize cancelled;
@synthesize playing;

-(void)decodeLocalFile:(LocalFile *)file fromPosition:(NSTimeInterval)startTime {
	
	[self performSelectorInBackground:@selector(decodeAssetOnThreadWithProperties:)
						   withObject:[NSDictionary dictionaryWithObjectsAndKeys:
									   file.path, @"path",
									   [NSNumber numberWithDouble:startTime], @"start", nil]];
	
}

-(void)decodeAssetOnThreadWithProperties:(NSDictionary *)properties {
	
	@autoreleasepool {
		
		NSString *path = [properties valueForKey:@"path"];
		NSTimeInterval startTime = [[properties valueForKey:@"start"] doubleValue];
		
		FLAC__StreamDecoder *decoder = FLAC__stream_decoder_new();
		
		if (decoder == NULL) {
			NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't init decoder!");
			[self performSelectorOnMainThread:@selector(endPlaybackThread) withObject:nil waitUntilDone:NO];
			return;
		}
		
		const char *path_cstr = [path UTF8String];
		
		FLAC__StreamDecoderInitStatus init_status = FLAC__stream_decoder_init_file(decoder,
																				   path_cstr,
																				   FLAC_write_callback,
																				   FLAC_metadata_callback,
																				   FLAC_error_callback,
																				   (__bridge void *)self);
		
		if(init_status != FLAC__STREAM_DECODER_INIT_STATUS_OK) {
			NSLog(@"[%@ %@]: %@ %s", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't init decoder:", FLAC__StreamDecoderInitStatusString[init_status]);
			[self performSelectorOnMainThread:@selector(endPlaybackThread) withObject:nil waitUntilDone:NO];
			return;
		}
		
		// Read metadata
		FLAC__bool success = FLAC__stream_decoder_process_until_end_of_metadata(decoder);
		if (!success) {
			NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't read metadata");
			[self performSelectorOnMainThread:@selector(endPlaybackThread) withObject:nil waitUntilDone:NO];
			return;
		}

		if (startTime > 0.0)
			FLAC__stream_decoder_seek_absolute(decoder, (FLAC__int64)sample_rate * startTime);

		// We don't care if the decoding failed since aborting the decode manually counts as a failure.
		FLAC__stream_decoder_process_until_end_of_stream(decoder);
		
		FLAC__stream_decoder_delete(decoder);
		decoder = NULL;
		
		[self performSelectorOnMainThread:@selector(endPlaybackThread) withObject:nil waitUntilDone:NO];
	}
}

-(void)endPlaybackThread {
	[self.delegate workerDidCompleteAudioPlayback:self withError:self->decodingError];
}

static FLAC__StreamDecoderWriteStatus FLAC_write_callback(const FLAC__StreamDecoder *decoder, const FLAC__Frame *frame, const FLAC__int32 * const buffer[], void *client_data) {
	
	VivaFLACDecoderWorker *self = (__bridge VivaFLACDecoderWorker *)client_data;
	
	if (self.cancelled) return FLAC__STREAM_DECODER_WRITE_STATUS_ABORT;
	
	NSUInteger total_sample_count = frame->header.blocksize * self->channels;
	uint32_t interleaved_data[total_sample_count];	
	
	for(size_t i = 0; i < frame->header.blocksize; i++) {
		interleaved_data[i * 2] = buffer[0][i];
		interleaved_data[(i * 2) + 1] = buffer[1][i]; 
	}
	
	while (!self.isPlaying && !self.cancelled) {
		// Don't push audio data if we're paused.
		[NSThread sleepForTimeInterval:0.1];
	}
	
	while (!self.cancelled && ([self.delegate worker:self
							shouldDeliverAudioFrames:(const void *)&interleaved_data
											 ofCount:frame->header.blocksize
											  format:self->output_format] == 0)) {
		[NSThread sleepForTimeInterval:0.1];
	}
	
	return self.cancelled ? FLAC__STREAM_DECODER_WRITE_STATUS_ABORT : FLAC__STREAM_DECODER_WRITE_STATUS_CONTINUE;
}

static void FLAC_metadata_callback(const FLAC__StreamDecoder *decoder, const FLAC__StreamMetadata *metadata, void *client_data) {
	
	VivaFLACDecoderWorker *self = (__bridge VivaFLACDecoderWorker *)client_data;
	
	if(metadata->type == FLAC__METADATA_TYPE_STREAMINFO) {
		
		self->total_samples = metadata->data.stream_info.total_samples;
		self->sample_rate = metadata->data.stream_info.sample_rate;
		self->channels = metadata->data.stream_info.channels;
		self->bits_per_sample = metadata->data.stream_info.bits_per_sample;
		
		// The FLAC decoder gives us 32-bit samples even if the audio contained therein is
		// less than 32-bit.
		
		AudioStreamBasicDescription flacFormat;
		flacFormat.mSampleRate = self->sample_rate;
		flacFormat.mFormatID = kAudioFormatLinearPCM;
		flacFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian;
		flacFormat.mBytesPerPacket = (UInt32)(self->channels * sizeof(uint32_t));
		flacFormat.mFramesPerPacket = 1;
		flacFormat.mBytesPerFrame = flacFormat.mBytesPerPacket;
		flacFormat.mChannelsPerFrame = (UInt32)self->channels;
		flacFormat.mBitsPerChannel = (UInt32)self->bits_per_sample;
		flacFormat.mReserved = 0;
		
		self->output_format = flacFormat;
	}
}

static void FLAC_error_callback(const FLAC__StreamDecoder *decoder, FLAC__StreamDecoderErrorStatus status, void *client_data) {
	
	VivaFLACDecoderWorker *self = (__bridge VivaFLACDecoderWorker *)client_data;
	
	self->decodingError = [NSError errorWithDomain:@"com.spotify.Viva.FLACDecoder"
											  code:kVivaTrackDecodingFailedErrorCode
										  userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:FLAC__StreamDecoderErrorStatusString[status]]
																			   forKey:NSLocalizedDescriptionKey]];
}


@end
