//
//  VivaImageExtensions.m
//  Viva
//
//  Created by Daniel Kennett on 16/04/2011.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaImageExtensions.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@implementation NSImage (VivaImageExtensions)

static const double kDefaultMosaicImageSize = 300.0;
static const double kMinimumMosaicImageSize = 32.0;
static const double kMinimumMosaicBlockSize = 32.0;

+(NSImage *)mosaicImageWithTracks:(NSArray *)tracks {
	return [self mosaicImageWithTracks:tracks aspect:kDefaultMosaicImageSize];
}
	
+(NSImage *)mosaicImageWithTracks:(NSArray *)tracks aspect:(double)mosaicSideSize {
	
	NSMutableArray *imagesWeCanUse = [NSMutableArray array];
	
	for (SPSpotifyTrack *track in tracks) {
		
		SPSpotifyImage *spImage = [[track album] cover];
		
		if ([spImage image] != nil && ![imagesWeCanUse containsObject:spImage]) {
			[imagesWeCanUse addObject:spImage];
		}
	}
	
	NSImage *generatedImage = [NSImage mosaicImageWithSPImages:imagesWeCanUse aspect:mosaicSideSize];
	
	if (generatedImage == nil) {
		// TODO: Return "no image" image
		return nil;
	} else {
		return generatedImage;
	}

}

+(NSImage *)mosaicImageWithSPImages:(NSArray *)images {
	return [self mosaicImageWithSPImages:images aspect:kDefaultMosaicImageSize];
}

+(NSImage *)mosaicImageWithSPImages:(NSArray *)images aspect:(double)mosaicSideSize {
	
	double actualMosaicAspect = MAX(mosaicSideSize, kMinimumMosaicImageSize);
	
	NSImage *mosaicImage = [[NSImage alloc] initWithSize:NSMakeSize(actualMosaicAspect, actualMosaicAspect)];
	[mosaicImage lockFocus];
	
	NSUInteger mosaicEdgeCount = floor(sqrt((double)[images count]));
	
	if ((actualMosaicAspect / mosaicEdgeCount) < kMinimumMosaicImageSize) {
		mosaicEdgeCount = floor(actualMosaicAspect / kMinimumMosaicImageSize);
	}
	
	NSUInteger mosaicImageCount = mosaicEdgeCount * mosaicEdgeCount;
	
	if (mosaicImageCount == 0 || mosaicImageCount > [images count]) {
		return nil;
	}
	
	NSArray *imagesWeCanUse = [images objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, mosaicImageCount)]];
	
	NSUInteger tileEdgeCount = sqrtl([imagesWeCanUse count]);
	NSSize tileSize = NSMakeSize([mosaicImage size].width / tileEdgeCount, [mosaicImage size].width / tileEdgeCount);
	
	NSUInteger imagesDrawn = 0;
	for (SPSpotifyImage *spImage in imagesWeCanUse) {
		
		[[spImage image] drawInRect:(NSRect) {
			.origin = NSMakePoint((imagesDrawn % tileEdgeCount) * tileSize.width,
								  floor(imagesDrawn / tileEdgeCount) * tileSize.height),
			.size = tileSize
		}
						   fromRect:NSZeroRect
						  operation:NSCompositeCopy
						   fraction:1.0];
		
		imagesDrawn++;
		
	}
	
	[mosaicImage unlockFocus];
	return [mosaicImage autorelease];
}


@end
