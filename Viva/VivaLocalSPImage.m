//
//  VivaLocalSPImage.m
//  Viva
//
//  Created by Daniel Kennett on 17/03/2012.
//  For license information, see LICENSE.markdown
//

#import "VivaLocalSPImage.h"

@interface VivaLocalSPImage ()

@property (nonatomic, readwrite, copy) SPPlatformNativeImage *image;

@end


@implementation VivaLocalSPImage

-(id)initWithImage:(SPPlatformNativeImage *)im {
	
	self = [super init];
	
	if (self) {
		self.image = im;
		[self addObserver:self
               forKeyPath:@"loaded"
				  options:0
				  context:nil];
	}
	return self;
}

-(BOOL)isLoaded { return YES; }
-(const byte *)imageId { return NULL; }
-(SPSession *)session { return nil; }
-(sp_image *)spImage { return NULL; }
-(NSURL *)spotifyURL { return nil; }

@synthesize image;

@end
