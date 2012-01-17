//
//  SPBackgroundColorView.h
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>


@interface SPBackgroundColorView : NSView {
@private
    NSColor *backgroundColor;
}

@property (nonatomic, readwrite, strong) NSColor *backgroundColor;

@end
