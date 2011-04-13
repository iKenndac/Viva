// Copyright (c) 2009 Spotify AB
#import "NSObject+Spotify.h"
#import <execinfo.h>

#pragma mark Invocation grabbing
@interface SPInvocationGrabber ()
-(void)setObject:(id)obj;
-(void)setInvocation:(NSInvocation*)inv;
@end

@implementation SPInvocationGrabber
- (id)initWithObject:(id)obj;
{
	return [self initWithObject:obj stacktraceSaving:YES];
}

-(id)initWithObject:(id)obj stacktraceSaving:(BOOL)saveStack;
{
	self.object = obj;
	
	shouldSaveBacktrace = saveStack;

	return self;
}
-(void)dealloc;
{
	free(frameStrings);
	self.object = nil;
	self.invocation = nil;
	[super dealloc];
}
-(id)object; { return _object; }
-(void)setObject:(id)obj;
{
	[obj retain];
	[_object release];
	_object = obj;
}
-(NSInvocation*)invocation; { return _invocation; }
-(void)setInvocation:(NSInvocation*)inv;
{
	[inv retain];
	[_invocation release];
	_invocation = inv;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
	[anInvocation retainArguments];
	anInvocation.target = _object;
	self.invocation = anInvocation;
	if(shouldSaveBacktrace) [self saveBacktrace];
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)inSelector {
	NSMethodSignature *signature = [super methodSignatureForSelector:inSelector];
	if (signature == NULL)
		signature = [_object methodSignatureForSelector:inSelector];
    
	return signature;
}

- (void)invoke;
 {

	@try {
		[_invocation invoke];
	}
	@catch (NSException * e) {
		NSLog(@"While invoking -[%@ %@], SPInvocationGrabber's target raised %@ because %@. Stack trace:",
			self.object, NSStringFromSelector(self.invocation.selector), 
			e.name, e.reason
		);
		[self printBacktrace];
		[e raise];
	}

	self.invocation = nil;
	self.object = nil;
}

-(void)saveBacktrace;
{
if(NSAppKitVersionNumber < 949 /*NSAppKitVersionNumber10_5*/) return;
  void *backtraceFrames[128];
  frameCount = backtrace(&backtraceFrames[0], 128);
  frameStrings = backtrace_symbols(&backtraceFrames[0], frameCount);
}
-(void)printBacktrace;
{
	if(!frameCount) {
		NSLog(@"No stack trace was saved with the crashing invocation");
		return;
	}
	NSLog(@"Invocation was originally scheduled at:");
	for(int x = 3; x < frameCount; x++) {
		if(frameStrings[x] == NULL) { break; }
		NSLog(@"%s", frameStrings[x]);
	}
}
@end

@implementation NSObject (SPInvocationGrabbing)
-(id)grab;
{
	return [[[SPInvocationGrabber alloc] initWithObject:self] autorelease];
}
-(id)grabCheap;
{
	return [[[SPInvocationGrabber alloc] initWithObject:self stacktraceSaving:NO] autorelease];
}

-(id)invokeAfter:(NSTimeInterval)delta;
{
	id grabber = [[[SPInvocationGrabber alloc] initWithObject:self] autorelease];
	[NSTimer scheduledTimerWithTimeInterval:delta target:grabber selector:@selector(invoke) userInfo:nil repeats:NO];
	return grabber;
}
-(id)invokeAfterCheap:(NSTimeInterval)delta;
{
	id grabber = [[[SPInvocationGrabber alloc] initWithObject:self stacktraceSaving:NO] autorelease];
	[NSTimer scheduledTimerWithTimeInterval:delta target:grabber selector:@selector(invoke) userInfo:nil repeats:NO];
	return grabber;
}
- (id)nextRunloop {
	return [self invokeAfter:0];
}
@end


@implementation SPMultiObjectProxy
-(id)initWithObjects:(id)obj, ...;
{
	va_list vlist;
	va_start(vlist, obj);
	objects = [NSMutableArray new];
	do {
		[objects addObject:obj];
		obj = va_arg(vlist, id);
	} while(obj);
	va_end(vlist);
	return self;
}
-(void)dealloc;
{
	[objects release];
	[super dealloc];
}
-(NSArray*)objects;
{
	return objects;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
	for(int i = 0; i < [objects count]; i++)
		if([[objects objectAtIndex:i] respondsToSelector:anInvocation.selector])
			[anInvocation invokeWithTarget:[objects objectAtIndex:i]];
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)inSelector {
	NSMethodSignature *signature = [super methodSignatureForSelector:inSelector];
	if(signature) return signature;
	
	for(int i = 0; i < [objects count]; i++) {
		signature = [[objects objectAtIndex:i] methodSignatureForSelector:inSelector];
		if(signature) return signature;
	}
	return NULL;
}
-(BOOL)respondsToSelector:(SEL)sel;
{
	for(int i = 0; i < [objects count]; i++)
		if([[objects objectAtIndex:i] respondsToSelector:sel])
			return YES;
	return NO;
}

@end