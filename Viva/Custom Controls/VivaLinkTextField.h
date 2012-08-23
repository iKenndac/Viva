//
//  VivaLinkTextField.h
//  Viva
//
//  Created by Daniel Kennett on 04/04/2012.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>

static NSString * const kVivaLinkViewItemTitleKey = @"title";
static NSString * const kVivaLinkViewItemKey = @"item";

@class VivaLinkTextField;

@protocol VivaLinkTextFieldDelegate <NSObject>

-(void)textField:(VivaLinkTextField *)field didClickLinkForURL:(NSURL *)aURL;

@end

@interface VivaLinkTextField : NSView

@property (nonatomic, readwrite, assign) __unsafe_unretained id <VivaLinkTextFieldDelegate> delegate;
@property (readwrite, nonatomic, strong) NSArray *items;

@property (readwrite, nonatomic, strong) NSColor *activeColor;
@property (readwrite, nonatomic, strong) NSFont *textFont;


@end
