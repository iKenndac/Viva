#import "NCCommon.h"

@implementation NSString (NSStringContains)

-(BOOL)contains:(NSString*)needle;
{
    NSArray *ar = [self componentsSeparatedByString:needle];
    if([ar count] > 1)
        return YES;
    if([(NSString*)[ar objectAtIndex:0] compare:needle] == NSOrderedSame)
        return YES;
    return NO; 
}

@end

@implementation NSArray (NSArrayFirstObject)
-(id)firstObject;
{
    return [self objectAtIndex:0];
}
@end

@implementation NSNumber (NSNumberBinaryRepresentation)
-(NSString*)binaryRepresentation;
{
    unsigned min = 0;
    char str[33];
    int me = [self intValue];
    for(int i = 31; i >= 0; i--) {
        BOOL bit = me & 1<<i;
        str[31-i] = bit?'1':'0';
        if(bit && !min)
            min = 31-i;
    }
    
    str[32] = 0;
    return s(str+min);
}
@end




NSRect NSRectByScaling(NSRect rect, float scale) {
	for(unsigned component = 0; component < 4; component++)
		((float*)(&rect))[component] = scale * ((float*)(&rect))[component];
	return rect;
}


NSString* s(const char *str) {
	return [NSString stringWithUTF8String:str];
}

/*
NSString *sf(NSString *format, ...)  {
	va_list va;
	va_start(va, format);
	NSString *str = [[[NSString alloc] initWithFormat:format arguments:va] autorelease];
	va_end(va);
	return str;
}
*/
#define sf(format, ...) ([NSString stringWithFormat: format, ##__VA_ARGS__])

NSArray *ary(id item, ...) {
	if(!item) return [NSMutableArray array];
	NSMutableArray *ar = [NSMutableArray arrayWithObject:item];
	
	va_list va;
	va_start(va, item);
	id obj = va_arg(va, id);
	while(obj != nil) {
		[ar addObject:obj];
		obj = va_arg(va, id);
	}
	va_end(va);
	return ar;
}

NSDictionary *dict(id key, id value, ...) {
	if(!key) return [NSMutableDictionary dictionary];
	NSMutableDictionary *mdict = [NSMutableDictionary dictionaryWithObject:value forKey:key];
	
	va_list va;
	va_start(va, value);
	id nextkey = va_arg(va, id);
	id val = va_arg(va, id);
	while(nextkey != nil && val != nil) {
		[mdict setObject:val forKey:nextkey];
		nextkey = va_arg(va, id);
		val = va_arg(va, id);
	}
	va_end(va);
	return mdict;
}

NSNumber *num(double n) {
	return [NSNumber numberWithDouble:n];
}

NSString *FourCCString(int fourCC)
{
    char str[5] = FourCC2Str(fourCC);
    return s(str);
}

