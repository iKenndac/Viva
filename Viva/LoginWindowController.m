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
#import "Constants.h"
#import "EMKeychainItem.h"

@interface LoginWindowController(ImTotallyAnNSViewIPromise)
-(float)roundedCornerRadius;
-(void)drawRectOriginal:(NSRect)rect;
-(NSWindow*)window;
@end

@implementation LoginWindow
@end

@implementation LoginWindowController

@synthesize isLoggingIn;
@synthesize userNameField;
@synthesize passwordField;
@synthesize rememberMeCheckbox;
@synthesize contentBox;
@synthesize credentialsView;
@synthesize loggingInView;

-(id)init {
	return [super initWithWindowNibName:@"LoginWindow"];
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"isLoggingIn"];
	[super dealloc];
}

- (void)windowDidLoad {
    
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
	
	NSString *userName = [[NSUserDefaults standardUserDefaults] valueForKey:kVivaLastUserNameUserDefaultsKey];
	EMKeychainItem *keychainItem = [EMGenericKeychainItem genericKeychainItemForService:kVivaKeychainServiceName
																		   withUsername:userName];
	NSString *password = keychainItem.password;
	
	if ([userName length] > 0)
		[userNameField setStringValue:userName];
	
	if ([password length] > 0)
		[passwordField setStringValue:password];
	
	if ([userName length] > 0 && [password length] > 0) {
		[self performSelector:@selector(attemptLogin:)
				   withObject:nil
				   afterDelay:0.0];
	}
	
	[self addObserver:self
		   forKeyPath:@"isLoggingIn"
			  options:NSKeyValueObservingOptionInitial
			  context:nil];
	
    [super windowDidLoad];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isLoggingIn"]) {
        
		if ([self isLoggingIn]) {
			[self.contentBox setContentView:self.loggingInView];
		} else {
			[self.contentBox setContentView:self.credentialsView];
		}
		
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)windowWillClose:(NSNotification *)notification {
	if (!self.isLoggingIn) {
		[NSApp terminate:self];
	}
}

- (IBAction)attemptLogin:(id)sender {
	
	if ([[userNameField stringValue] length] == 0 ||
		[[passwordField stringValue] length] == 0) {
		NSBeep();
		return;
	}
	
	if ([rememberMeCheckbox state] == NSOnState) {
		[EMGenericKeychainItem addGenericKeychainItemForService:kVivaKeychainServiceName
												   withUsername:[userNameField stringValue]
													   password:[passwordField stringValue]];
		
		[[NSUserDefaults standardUserDefaults] setValue:[userNameField stringValue]
												 forKey:kVivaLastUserNameUserDefaultsKey];
	}
	
	NSError *error = nil;
	[[SPSession sharedSession] attemptLoginWithApplicationKey:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"libspotify_appkey" ofType:@"key"]]
													userAgent:kVivaLibSpotifyUserAgentName
													 userName:[userNameField stringValue]
													 password:[passwordField stringValue]
														error:&error];
	
	if (error != nil) {
		[self presentError:error];
		return;
	}
	
	self.isLoggingIn = YES;
}

-(void)reset {
	self.isLoggingIn = NO;
	[passwordField setStringValue:@""];
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
