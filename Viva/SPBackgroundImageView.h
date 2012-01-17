//
//  SPBackgroundImageView.h
//  Viva
//
//  Created by Daniel Kennett on 6/13/11.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>

@interface SPBackgroundImageView : NSView {
@private
	NSImage *backgroundImage;
}

@property (nonatomic, readwrite, strong) NSImage *backgroundImage;

@end
