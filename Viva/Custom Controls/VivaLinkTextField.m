//
//  VivaLinkTextField.m
//  Viva
//
//  Created by Daniel Kennett on 04/04/2012.
//  For license information, see LICENSE.markdown
//

#import "VivaLinkTextField.h"
#import "VivaAppDelegate.h"

@interface VivaLinkTextField ()

@property (readwrite, nonatomic) NSPoint currentMousePoint;
@property (readwrite, nonatomic, copy) NSDictionary *cachedRects;
@property (readwrite, nonatomic) NSBackgroundStyle backgroundStyle;

@end

@implementation VivaLinkTextField

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self addObserver:self forKeyPath:@"items" options:0 context:nil];
		self.currentMousePoint = NSMakePoint(-1.0, -1.0);
		self.activeColor = [NSColor blackColor];
		self.textFont = [NSFont systemFontOfSize:12.0];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code here.
		[self addObserver:self forKeyPath:@"items" options:0 context:nil];
		self.currentMousePoint = NSMakePoint(-1.0, -1.0);
		self.activeColor = [NSColor blackColor];
		self.textFont = [NSFont systemFontOfSize:12.0];
    }
    
    return self;
}

@synthesize delegate;
@synthesize items;
@synthesize currentMousePoint;
@synthesize cachedRects;
@synthesize backgroundStyle = _backgroundStyle;

-(void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
	_backgroundStyle = backgroundStyle;
	[self setNeedsDisplay:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"items"]) {
		self.cachedRects = [self generateCachedRects];
		[self setNeedsDisplay:YES];
		
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"items"];
}

-(BOOL)acceptsFirstResponder {
	return YES;
}

-(NSDictionary *)textProperties:(BOOL)underline enabled:(BOOL)enabled {
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
	[dict setValue:self.textFont forKey:NSFontAttributeName];
	[dict setValue:self.backgroundStyle == NSBackgroundStyleDark ? [NSColor whiteColor] : enabled ? self.activeColor : [NSColor disabledControlTextColor] forKey:NSForegroundColorAttributeName];
	
	NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
	paragraph.lineBreakMode = NSLineBreakByTruncatingTail;
	
	[dict setValue:paragraph forKey:NSParagraphStyleAttributeName];
	
	if (underline)
		[dict setValue:[NSNumber numberWithInt:NSUnderlineStyleSingle] forKey:NSUnderlineStyleAttributeName];
	
	return dict;
	
	
}

-(NSDictionary *)generateCachedRects {
	
	CGRect paddedBounds = NSInsetRect(self.bounds, 5.0, 0.0);
	CGFloat currentX = paddedBounds.origin.x;
	
	NSMutableDictionary *rects = [NSMutableDictionary dictionaryWithCapacity:self.items.count];
	
	for (NSInteger currentItemIndex = 0; currentItemIndex < self.items.count; currentItemIndex++) {
		
		NSMutableDictionary *currentItem = [[self.items objectAtIndex:currentItemIndex] mutableCopy];
		
		NSString *title = [currentItem valueForKey:kVivaLinkViewItemTitleKey];
		if (currentItemIndex < (self.items.count - 1)) {
			title = [NSString stringWithFormat:@"%@, ", title];
			[currentItem setValue:title forKey:kVivaLinkViewItemTitleKey];
		}
		
		NSSize textSize = [title sizeWithAttributes:[self textProperties:NO enabled:YES]];
		
		CGFloat rectWidth = textSize.width;
		if ((paddedBounds.size.width - currentX) < rectWidth)
			rectWidth = (paddedBounds.size.width - currentX);
		
		CGFloat targetY = paddedBounds.origin.y + ((paddedBounds.size.height / 2) - (textSize.height / 2)); 
		NSRect targetRect = NSMakeRect(currentX, targetY, rectWidth, textSize.height);
		
		if (targetRect.size.width > 5.0)
			[rects setObject:currentItem forKey:[NSValue valueWithRect:targetRect]];
		
		currentX += targetRect.size.width;
	};
	
	return rects;
}

-(void)drawRect:(NSRect)dirtyRect {

	for (NSValue *rectValue in self.cachedRects.allKeys) {
		
		NSRect rect = rectValue.rectValue;
		
		if (!NSIntersectsRect(rect, dirtyRect))
			continue;
		
		NSString *title = [[self.cachedRects objectForKey:rectValue] valueForKey:kVivaLinkViewItemTitleKey];
		id originalItem = [[self.cachedRects objectForKey:rectValue] valueForKey:kVivaLinkViewItemKey];
		
		[title drawInRect:rect
		   withAttributes:[self textProperties:originalItem != nil && NSPointInRect(self.currentMousePoint, rect)
									   enabled:originalItem != nil]];
	}
}

-(void)setFrame:(NSRect)frameRect {
	[super setFrame:frameRect];
	self.cachedRects = [self generateCachedRects];
}

-(void)resetCursorRects {
	
	NSArray *trackingAreas = [self.trackingAreas copy];
	for (NSTrackingArea *area in trackingAreas)
		[self removeTrackingArea:area];
	
	for (NSValue *rectValue in self.cachedRects.allKeys) {
		
		NSDictionary *item = [self.cachedRects objectForKey:rectValue];
		if ([item valueForKey:kVivaLinkViewItemKey] == nil)
			continue;
		
		NSRect rect = rectValue.rectValue;
		[self addCursorRect:rect cursor:[NSCursor pointingHandCursor]];		
		
		NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:rect 
															options:NSTrackingActiveInActiveApp | NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved
															  owner:self
														   userInfo:nil];
		[self addTrackingArea:area];
	}
}

-(void)mouseEntered:(NSEvent *)theEvent {
	self.currentMousePoint = [self convertPoint:theEvent.locationInWindow fromView:nil];
	[self setNeedsDisplay:YES];
	[super mouseEntered:theEvent];
}

-(void)mouseExited:(NSEvent *)theEvent {
	self.currentMousePoint = NSMakePoint(-1.0, -1.0);
	[self setNeedsDisplay:YES];
	[super mouseExited:theEvent];
}

-(void)mouseMoved:(NSEvent *)theEvent {
	self.currentMousePoint = [self convertPoint:theEvent.locationInWindow fromView:nil];
	[self setNeedsDisplay:YES];
}

-(void)mouseDown:(NSEvent *)theEvent {
	
	NSPoint downPoint = [self convertPoint:theEvent.locationInWindow fromView:nil];
	
	for (NSValue *rectValue in self.cachedRects.allKeys) {
		
		NSRect rect = rectValue.rectValue;
		if (NSPointInRect(downPoint, rect))
			return;
	}
	
	[super mouseDown:theEvent];
}

-(void)mouseUp:(NSEvent *)theEvent {
	
	NSPoint upPoint = [self convertPoint:theEvent.locationInWindow fromView:nil];
	
	for (NSValue *rectValue in self.cachedRects.allKeys) {
		
		NSRect rect = rectValue.rectValue;
		if (NSPointInRect(upPoint, rect)) {
			id value = [self.cachedRects objectForKey:rectValue];
			NSURL *url = [value valueForKey:kVivaLinkViewItemKey];
			if (url != nil) {
				[[NSApp delegate] handleURL:url];
				
				// Nasty-ish hack since the view is immediately hidden
				self.currentMousePoint = NSMakePoint(-1.0, -1.0);
				[self setNeedsDisplay:YES];
				
			}
			break;
		}
	}
}


@end
