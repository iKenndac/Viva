//
//  SPCircularBuffer.h
//  Viva
//
//  Created by Daniel Kennett on 4/9/11.
//  Copyright 2011 Spotify. All rights reserved.
//

/** This class is a simple implementation of a circular buffer, designed to match the behaviour of (Cocoa)LibSpotify.
 
 This class gets around the problem of filling the buffer too far ahead by having a maximum size. Once that
 size is reached, you cannot add more data without reading some out or clearing it and starting again. When 
 used with (Cocoa)LibSpotify, this isn't a problem as we can ask the library to re-deliver audio data at a later time.
 */

#import <Foundation/Foundation.h>

@interface SPCircularBuffer : NSObject {
@private
    void *buffer;
	NSUInteger maximumLength;
	NSUInteger dataStartOffset;
	NSUInteger dataEndOffset;
	BOOL empty;
}

/** Initialize a new buffer. 
 
 Initial size will be zero, with a maximum size as provided.
 
 @param size The maximum size of the buffer, in bytes. 
 @return Returns the newly created SPCircularBuffer.
 */
-(id)initWithMaximumLength:(NSUInteger)size;

/** Clears all data from the buffer. */
-(void)clear;

/** Attempt to copy new data into the buffer.
 
 Data is copied using the following heuristic:
 
 - If dataLength <= (maximumLength - length), copy all data.
 - Otherwise, copy (maximumLength - length) bytes.
 
 @param data A buffer containing the data to be copied in.
 @param dataLength The length of the data, in bytes.
 @return Returns the amount of data copied into the buffer, in bytes. If this number is 
 smaller than dataLength, only this number of bytes was copied in from the start of the given buffer.
 */
-(NSUInteger)attemptAppendData:(const void *)data ofLength:(NSUInteger)dataLength;

/** Read data out of the buffer.
 
 @warning *Important:* If this method returns non-zero, you _must_ free() the given buffer to 
 not leak memory.
 
 @param desiredLength The desired number of bytes to copy out.
 @param outBuffer A pointer to a buffer, which will be malloc()ed and filled with the read data. 
 @return Returns the amount of data copied into the given buffer, in bytes.
 */
-(NSUInteger)readDataOfLength:(NSUInteger)desiredLength intoBuffer:(void **)outBuffer;

/** Returns the amount of data currently in the buffer, in bytes. */
@property (readonly) NSUInteger length;

/** Returns the maximum amount of data that the buffer can hold, in bytes. */
@property (readonly) NSUInteger maximumLength;

@end
