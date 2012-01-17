//
//  LoginWindowController.h
//  Viva
//
//  Created by Daniel Kennett on 3/27/11.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>

@interface LoginWindow : NSWindow
// This exists so our NSThemeFrame swizzling can tell if it should draw custom stuff or not.
@end

@interface LoginWindowController : NSWindowController {
@private
    
	NSTextField *__weak userNameField;
	NSSecureTextField *__weak passwordField;
	NSButton *__weak rememberMeCheckbox;
	NSBox *__weak contentBox;
	NSView *__weak credentialsView;
	NSView *__weak loggingInView;
	
	BOOL isLoggingIn;
}

@property (readwrite) BOOL isLoggingIn;

@property (weak) IBOutlet NSTextField *userNameField;
@property (weak) IBOutlet NSSecureTextField *passwordField;
@property (weak) IBOutlet NSButton *rememberMeCheckbox;
@property (weak) IBOutlet NSBox *contentBox;
@property (weak) IBOutlet NSView *credentialsView;
@property (weak) IBOutlet NSView *loggingInView;

- (IBAction)attemptLogin:(id)sender;
-(void)reset;

@end
