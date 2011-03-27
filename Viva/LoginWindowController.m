//
//  LoginWindowController.m
//  Viva
//
//  Created by Daniel Kennett on 3/27/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "LoginWindowController.h"
#import <objc/runtime.h>
#import "VivaAppDelegate.h"

@interface LoginWindowController(ImTotallyAnNSViewIPromise)
-(float)roundedCornerRadius;
-(void)drawRectOriginal:(NSRect)rect;
-(NSWindow*)window;
@end

@implementation LoginWindow
@end

@implementation LoginWindowController
@synthesize userNameField;
@synthesize passwordField;
@synthesize rememberMeCheckbox;

-(id)init {
	return [super initWithWindowNibName:@"LoginWindow"];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	
	// Get window's frame view class
	id class = [[[self.window contentView] superview] class];
	
	// Exchange draw rect
	Method m0 = class_getInstanceMethod([self class], @selector(drawRect:));
	class_addMethod(class, @selector(drawRectOriginal:), method_getImplementation(m0), method_getTypeEncoding(m0));
	
	Method m1 = class_getInstanceMethod(class, @selector(drawRect:));
	Method m2 = class_getInstanceMethod(class, @selector(drawRectOriginal:));
	
	method_exchangeImplementations(m1, m2);
	
	[[[self.window contentView] superview] setNeedsDisplay:YES];
	
	[self.window center];
}

-(void)windowWillClose:(NSNotification *)notification {
	[NSApp terminate:self];
}

- (IBAction)attemptLogin:(id)sender {
	
	[[(VivaAppDelegate *)[NSApp delegate] session] attemptLoginWithUserName:[userNameField stringValue]
																   password:[passwordField stringValue]];
	
}

#pragma mark -
#pragma mark Custom Window Drawing

// Thanks to http://parmanoir.com/Custom_NSThemeFrame for the code!

- (void)drawRect:(NSRect)rect {
	
	// Call original drawing method
	[self drawRectOriginal:rect];
	
	if (![NSStringFromClass([[self window] class]) isEqualToString:@"LoginWindow"]) 
		// isKindOfClass: won't work here, I'm guessing because this method is implemented from the context of 
		// NSThemeView, which doesn't know about my classes? Who knows...
		return;
	//
	// Build clipping path : intersection of frame clip (bezier path with rounded corners) and rect argument
	//
	NSRect windowRect = [[self window] frame];
	windowRect.origin = NSMakePoint(0, 0);
	
	float cornerRadius = [self roundedCornerRadius];
	[[NSBezierPath bezierPathWithRect:rect] addClip];
	[[NSBezierPath bezierPathWithRoundedRect:windowRect xRadius:cornerRadius yRadius:cornerRadius] addClip];
	
	NSRect imageRect = windowRect;
	
	[[NSImage imageNamed:@"background"] drawInRect:imageRect
										  fromRect:windowRect 
										 operation:NSCompositeSourceOver
										  fraction:1.0];
}

@end
