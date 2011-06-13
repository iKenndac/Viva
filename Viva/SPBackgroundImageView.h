//
//  SPBackgroundImageView.h
//  Viva
//
//  Created by Daniel Kennett on 6/13/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SPBackgroundImageView : NSView {
@private
	NSImage *backgroundImage;
}

@property (nonatomic, readwrite, retain) NSImage *backgroundImage;

@end
