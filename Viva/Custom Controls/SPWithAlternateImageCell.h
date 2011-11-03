//
//  SPWithAlternateImageCell.h
//  Viva
//
//  Created by Daniel Kennett on 4/14/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SPWithAlternateImageCell : NSImageCell {
@private
	NSImage *alternateImage;
}

@property (nonatomic, readwrite, strong) NSImage *alternateImage;

@end
