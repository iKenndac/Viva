//
//  SPWithAlternateImageCell.h
//  Viva
//
//  Created by Daniel Kennett on 4/14/11.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>


@interface SPWithAlternateImageCell : NSImageCell {
@private
	NSImage *alternateImage;
}

@property (nonatomic, readwrite, strong) NSImage *alternateImage;

@end
