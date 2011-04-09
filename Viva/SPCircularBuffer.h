//
//  SPCircularBuffer.h
//  Viva
//
//  Created by Daniel Kennett on 4/9/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SPCircularBuffer : NSObject {
@private
    void *buffer;
	NSUInteger maximumLength;
	NSUInteger dataStartOffset;
	NSUInteger dataEndOffset;
	BOOL empty;
}

-(id)initWithMaximumLength:(NSUInteger)size;

// Clear the buffer
-(void)clear;

// Copy data to the buffer. Returns the amound of data appended to the buffer from the given data.
-(NSUInteger)attemptAppendData:(const void *)data ofLength:(NSUInteger)dataLength;

// Read some data from the buffer. Returns the amount of data copied into outBuffer. You must free() outBuffer when you're done IF this method returns more than 0.
-(NSUInteger)readDataOfLength:(NSUInteger)desiredLength intoBuffer:(void **)outBuffer;

// The amount of data currently in the buffer.
@property (readonly) NSUInteger length;

// The maximum size of the buffer.
@property (readonly) NSUInteger maximumLength;

@end
