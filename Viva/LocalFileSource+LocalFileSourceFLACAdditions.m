//
//  LocalFileSource+LocalFileSourceFLACAdditions.m
//  Viva
//
//  Created by Daniel Kennett on 03/02/2012.
//  For license information, see LICENSE.markdown
//

#import "LocalFileSource+LocalFileSourceFLACAdditions.h"
#import "stream_decoder.h"
#import "Constants.h"
#import "LocalFile.h"

static FLAC__StreamDecoderWriteStatus FLAC_LocalFileSource_write_callback(const FLAC__StreamDecoder *decoder, const FLAC__Frame *frame, const FLAC__int32 * const buffer[], void *client_data);
static void FLAC_LocalFileSource_metadata_callback(const FLAC__StreamDecoder *decoder, const FLAC__StreamMetadata *metadata, void *client_data);
static void FLAC_LocalFileSource_error_callback(const FLAC__StreamDecoder *decoder, FLAC__StreamDecoderErrorStatus status, void *client_data);


@implementation LocalFileSource (LocalFileSourceFLACAdditions)

-(LocalFile *)parseMediaFileWithFLACAtPath:(NSString *)path intoContext:(NSManagedObjectContext *)context {
	
	FLAC__StreamDecoder *decoder = FLAC__stream_decoder_new();
	
	if (decoder == NULL) {
		NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't init decoder!");
		return nil;
	}
	
	FLAC__stream_decoder_set_metadata_respond_all(decoder);
	
	const char *path_cstr = [path UTF8String];
	
	NSMutableDictionary *metadata = [NSMutableDictionary dictionary];
	
	FLAC__StreamDecoderInitStatus init_status = FLAC__stream_decoder_init_file(decoder,
																			   path_cstr,
																			   FLAC_LocalFileSource_write_callback,
																			   FLAC_LocalFileSource_metadata_callback,
																			   FLAC_LocalFileSource_error_callback,
																			   (__bridge void *)metadata);
	
	if(init_status != FLAC__STREAM_DECODER_INIT_STATUS_OK) {
		NSLog(@"[%@ %@]: %@ %s", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't init decoder:", FLAC__StreamDecoderInitStatusString[init_status]);
		return nil;
	}
	
	// Read metadata
	FLAC__bool success = FLAC__stream_decoder_process_until_end_of_metadata(decoder);
	if (!success) {
		NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't read metadata");
		return nil;
	}
	
	// Have metadata!
	NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), metadata);
	
	NSString *title = [metadata valueForKey:kFLACMetadataTitleKey];
	NSString *artist = [metadata valueForKey:kFLACMetadataArtistKey];
	NSString *album = [metadata valueForKey:kFLACMetadataAlbumKey];
	
	if (title.length == 0) {
		title = [[path lastPathComponent] stringByDeletingPathExtension];
	}
	
	FLAC__uint64 total_samples = FLAC__stream_decoder_get_total_samples(decoder);
	NSTimeInterval duration = total_samples / [[metadata valueForKey:kFLACMetadataStreamInfoSampleRateKey] doubleValue];
	
	LocalFile *file = [[LocalFile alloc] initWithEntity:[NSEntityDescription entityForName:@"LocalFile" inManagedObjectContext:context]
						 insertIntoManagedObjectContext:context];
	
	file.title = title;
	file.artist = artist;
	file.album = album;
	file.path = path;
	file.duration = [NSNumber numberWithDouble:duration];
	
	FLAC__stream_decoder_delete(decoder);
	decoder = NULL;
	
	return file;
}

static void FLAC_LocalFileSource_metadata_callback(const FLAC__StreamDecoder *decoder, const FLAC__StreamMetadata *metadata, void *client_data) {
	
	NSMutableDictionary *metadataDict = (__bridge NSMutableDictionary *)client_data;
	
	//NSLog(@"Got metadata");
	
	if (metadata->type == FLAC__METADATA_TYPE_PADDING) {
		//NSLog(@"Got padding");
	}
	
	if (metadata->type == FLAC__METADATA_TYPE_PICTURE) {
		//NSLog(@"Got picture");
	}
	
	if (metadata->type == FLAC__METADATA_TYPE_SEEKTABLE) {
		//NSLog(@"Got seek table");
	}
	
	if (metadata->type == FLAC__METADATA_TYPE_STREAMINFO) {
		// Set the sample rate, since we need it for duration and we don't otherwise get it unless
		// we start decoding audio data.
		[metadataDict setValue:[NSNumber numberWithUnsignedInt:metadata->data.stream_info.sample_rate] forKey:kFLACMetadataStreamInfoSampleRateKey];
	}	
	
	if (metadata->type == FLAC__METADATA_TYPE_CUESHEET) {
		//NSLog(@"Got cuesheet");
	} 
	
	if (metadata->type == FLAC__METADATA_TYPE_APPLICATION) {
		//NSLog(@"Got application");
	}
	
	if (metadata->type == FLAC__METADATA_TYPE_VORBIS_COMMENT) {
		
		FLAC__uint32 commentCount = metadata->data.vorbis_comment.num_comments;
		
		for (int commentIndex = 0; commentIndex < commentCount; commentIndex++) {
			
			FLAC__StreamMetadata_VorbisComment_Entry comment = metadata->data.vorbis_comment.comments[commentIndex];
			
			NSString *commentString = [NSString stringWithUTF8String:(const char *)comment.entry];
			NSRange delimeterRange = [commentString rangeOfString:@"="];
			
			if (delimeterRange.location == NSNotFound)
				continue;
			
			NSString *commentKey = [commentString substringToIndex:delimeterRange.location];
			NSString *commentValue = [commentString substringFromIndex:delimeterRange.location + delimeterRange.length];
			
			if (commentKey.length > 0 && commentValue.length > 0)
				[metadataDict setValue:commentValue forKey:commentKey];
		}
	}
}

static FLAC__StreamDecoderWriteStatus FLAC_LocalFileSource_write_callback(const FLAC__StreamDecoder *decoder, const FLAC__Frame *frame, const FLAC__int32 * const buffer[], void *client_data) {
	return FLAC__STREAM_DECODER_WRITE_STATUS_CONTINUE;
}

static void FLAC_LocalFileSource_error_callback(const FLAC__StreamDecoder *decoder, FLAC__StreamDecoderErrorStatus status, void *client_data) {
	// Don't care?
}


@end
