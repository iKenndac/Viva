//
//  SPCircularBuffer.m
//  Viva
//
//  Created by Daniel Kennett on 4/9/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "SPCircularBuffer.h"


@implementation SPCircularBuffer

- (id)init {
    return [self initWithMaximumLength:1024];
}

-(id)initWithMaximumLength:(NSUInteger)size {
	self = [super init];
    if (self) {
        // Initialization code here.
		buffer = malloc(size);
		maximumLength = size;
		[self clear];
    }
    
    return self;
}

-(void)clear {
	@synchronized(self) {
		[self willChangeValueForKey:@"length"];
		memset(buffer, 0, maximumLength);
		dataStartOffset = 0;
		dataEndOffset = 0;
		empty = YES;
		[self didChangeValueForKey:@"length"];
	}
}

-(NSUInteger)attemptAppendData:(const void *)data ofLength:(NSUInteger)dataLength {
	@synchronized(self) {
		NSUInteger availableBufferSpace = self.maximumLength - self.length;
	
		if (availableBufferSpace == 0)
			return 0;
		
		[self willChangeValueForKey:@"length"];
		
		NSUInteger writableByteCount = MIN(dataLength, availableBufferSpace);
		NSUInteger directCopyByteCount = MIN(writableByteCount, self.maximumLength - (dataEndOffset + 1));
		NSUInteger wraparoundByteCount = writableByteCount - directCopyByteCount;
		
		if (directCopyByteCount > 0) {
			void *writePtr = buffer + (empty ? 0 : dataEndOffset + 1);
			memcpy(writePtr, data, directCopyByteCount);
			dataEndOffset += (empty ? directCopyByteCount - 1 : directCopyByteCount);
		}
		
		if (wraparoundByteCount > 0) {
			memcpy(buffer, data + directCopyByteCount, wraparoundByteCount);
			dataEndOffset = wraparoundByteCount - 1;
		}
		
		[self didChangeValueForKey:@"length"];
		
		if (writableByteCount > 0)
			empty = NO;
		
		return writableByteCount;
	}
}

-(NSUInteger)readDataOfLength:(NSUInteger)desiredLength intoBuffer:(void **)outBuffer {
	
	if (outBuffer == NULL || desiredLength == 0)
		return 0;
	
	@synchronized(self) {
		NSUInteger usedBufferSpace = self.length;
		
		if (usedBufferSpace == 0) {
			return 0;
		}
		
		[self willChangeValueForKey:@"length"];
		
		NSUInteger readableByteCount = MIN(usedBufferSpace, desiredLength);
		NSUInteger directCopyByteCount = MIN(readableByteCount, self.maximumLength - dataStartOffset);
		NSUInteger wraparoundByteCount = readableByteCount - directCopyByteCount;
		
		void *destinationBuffer = malloc(readableByteCount);
		
		if (directCopyByteCount > 0) {
			memcpy(destinationBuffer, buffer + dataStartOffset, directCopyByteCount);
			dataStartOffset += directCopyByteCount;
		}
		
		if (wraparoundByteCount > 0) {
			memcpy(destinationBuffer + directCopyByteCount, buffer, wraparoundByteCount);
			dataStartOffset = wraparoundByteCount;
		}
		
		[self didChangeValueForKey:@"length"];
		
		*outBuffer = destinationBuffer;
		return readableByteCount;
	}
	
}

-(NSUInteger)length {
	// Length is the distance between the start offset (start of the data)
	// and the end offset (end).
	@synchronized(self) {
		if (dataStartOffset == dataEndOffset) {
			// Empty!
			return 0;
		} else if (dataEndOffset > dataStartOffset) {
			return dataEndOffset - dataStartOffset;
		} else {
			return (maximumLength - dataStartOffset) + dataEndOffset;
		}
	}
}

@synthesize maximumLength;

- (void)dealloc {
	@synchronized(self) {
		memset(buffer, 0, maximumLength);
		free(buffer);
		[super dealloc];
	}
}

@end
