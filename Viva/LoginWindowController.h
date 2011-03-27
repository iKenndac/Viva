//
//  LoginWindowController.h
//  Viva
//
//  Created by Daniel Kennett on 3/27/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LoginWindow : NSWindow
// This exists so our NSThemeFrame swizzling can tell if it should draw custom stuff or not.
@end

@interface LoginWindowController : NSWindowController {
@private
    
	NSTextField *userNameField;
	NSSecureTextField *passwordField;
	NSButton *rememberMeCheckbox;
}
@property (assign) IBOutlet NSTextField *userNameField;
@property (assign) IBOutlet NSSecureTextField *passwordField;
@property (assign) IBOutlet NSButton *rememberMeCheckbox;

- (IBAction)attemptLogin:(id)sender;

@end
