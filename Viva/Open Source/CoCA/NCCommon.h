#import <Cocoa/Cocoa.h>

#define CLAMP(x, low, high)  (((x) > (high)) ? (high) : (((x) < (low)) ? (low) : (x)))


#define foreachGetEnumerator(c) \
([c respondsToSelector:@selector(objectEnumerator)] ? \
 [c objectEnumerator] : \
 c)
#define foreachGetIMP(e) \
[foreachEnum methodForSelector:@selector(nextObject)]
#define foreachCallIMP(imp, e) \
((IMP)imp)(e, @selector(nextObject))
#define foreachGetFirst(imp, e) \
(e ? foreachCallIMP(imp, e) : nil)
#define foreach(object, collection) \
for ( id foreachCollection = collection, \
	  foreachEnum = foreachGetEnumerator(foreachCollection), \
	  foreachIMP = (id)foreachGetIMP(foreachEnum), \
	  object = foreachGetFirst(foreachIMP, foreachEnum); \
	  object; \
	  object = foreachCallIMP(foreachIMP, foreachEnum) )
#define foreacht(type, object, collection) \
for ( type foreachCollection = (id)collection, \
	  *foreachEnum = (id)foreachGetEnumerator((id)foreachCollection), \
	  *foreachIMP = (id)foreachGetIMP((id)foreachEnum), \
	  *object = foreachGetFirst(foreachIMP, foreachEnum); \
	  object; \
	  object = foreachCallIMP(foreachIMP, foreachEnum) )


#define MakeSetter(ivarName, type, ivar) -(void)set##ivarName:(type)a##ivar { \
    [a##ivar retain]; \
	[self->ivar release]; \
	self->ivar = a##ivar; \
}

#define MakeCSetter(ivarName, type, ivar) -(void)set##ivarName:(type)a##ivar { \
	self->ivar = a##ivar; \
}

#define MakeGetter(type, ivar) -(type)ivar {\
	return ivar; \
}

#define MakeAccessor(ivarName, type, ivar) \
	MakeGetter(type, ivar); \
	MakeSetter(ivarName, type, ivar);

#define MakeCAccessor(ivarName, type, ivar) \
	MakeGetter(type, ivar); \
	MakeCSetter(ivarName, type, ivar);

#include <TargetConditionals.h>
#if TARGET_RT_BIG_ENDIAN
#   define FourCC2Str(fourcc) {*((char*)&fourcc), *(((char*)&fourcc)+1), *(((char*)&fourcc)+2), *(((char*)&fourcc)+3),0}
#else
#   define FourCC2Str(fourcc) {*(((char*)&fourcc)+3), *(((char*)&fourcc)+2), *(((char*)&fourcc)+1), *(((char*)&fourcc)+0),0}
#endif

extern NSString *FourCCString(int fourCC);

	
/*
extern NSString* NCMakeRectString(NSRect r) {
	return [NSString stringWithFormat:@"(%.1f, %.1f)[%.1f %.1f]", r.origin.x, r.origin.y, r.size.width, r.size.height];
}*/
#define NCMakeRectString NSStringFromRect


extern NSRect NSRectByScaling(NSRect rect, float scale);

extern NSString* s(const char *str);

/*
extern NSString *sf(NSString *format, ...)  {
	va_list va;
	va_start(va, format);
	NSString *str = [[[NSString alloc] initWithFormat:format arguments:va] autorelease];
	va_end(va);
	return str;
}
*/
#define sf(format, ...) ([NSString stringWithFormat: format, ##__VA_ARGS__])

extern NSArray *ary(id item, ...);

extern NSDictionary *dict(id key, id value, ...);

extern NSNumber *num(double n);

@interface NSString (NSStringContains)
-(BOOL)contains:(NSString*)needle;
@end

@interface NSArray (NSArrayFirstObject)
-(id)firstObject;
@end

@interface NSNumber (NSNumberBinaryRepresentation)
-(NSString*)binaryRepresentation;
@end


#define CGColorMakeGCd (CGColorRef)CFMakeCollectable