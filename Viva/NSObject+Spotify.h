// Copyright (c) 2009 Spotify AB

#import <Foundation/Foundation.h>

@interface SPInvocationGrabber : NSObject {
	id _object;
	NSInvocation *_invocation;
	bool shouldSaveBacktrace;
	int frameCount;
	char **frameStrings;
}
-(id)initWithObject:(id)obj;
-(id)initWithObject:(id)obj stacktraceSaving:(BOOL)saveStack;
-(id)object;
-(NSInvocation*)invocation;
-(void)invoke; // will release object and invocation
-(void)printBacktrace;
-(void)saveBacktrace;
@end

@interface NSObject (SPInvocationGrabbing)
-(id)grab;
-(id)grabCheap; // no stack trace
-(id)invokeAfter:(NSTimeInterval)delta;
-(id)invokeAfterCheap:(NSTimeInterval)delta;
-(id)nextRunloop;
@end



@interface SPMultiObjectProxy : NSProxy {
	NSMutableArray *objects;
}
-(id)initWithObjects:(id)obj, ... NS_REQUIRES_NIL_TERMINATION;
-(NSArray*)objects;
@end
