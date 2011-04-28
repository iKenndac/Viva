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
	
	for (SPTrack *track in tracks) {
		
		SPImage *spImage = [[track album] cover];
		
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
	for (SPImage *spImage in imagesWeCanUse) {
		
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

#pragma mark Decorated

+(NSImage *)decoratedMosaicWithTracks:(NSArray *)tracks badgeLabel:(NSString *)label {
	return [self decoratedMosaicWithTracks:tracks badgeLabel:label aspect:kDefaultMosaicImageSize];
}

+(NSImage *)decoratedMosaicWithTracks:(NSArray *)tracks badgeLabel:(NSString *)label aspect:(double)mosaicSideSize {
	
	NSImage *mosaic = [self mosaicImageWithTracks:tracks aspect:mosaicSideSize];
	
	if (mosaic == nil)
		return nil;
	
	NSImage *badge = nil;
	
	if ([label length] > 0) {
		
		NSMutableParagraphStyle *para = [[[NSMutableParagraphStyle alloc] init] autorelease];
		[para setAlignment:NSCenterTextAlignment];
		
		// Create attributes for drawing the count.
		NSDictionary * attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:11.0],
									 NSFontAttributeName, [NSColor whiteColor],
									 NSForegroundColorAttributeName,
									 para, NSParagraphStyleAttributeName, nil];
		
		NSSize numSize = [label sizeWithAttributes:attributes];
		
		// Create a red circle in the icon large enough to hold the count.
		
		NSImage *ballLeft = [NSImage imageNamed:@"dragBallLeft"];
		NSImage *ballRight = [NSImage imageNamed:@"dragBallRight"];
		NSImage *ballMiddle = [NSImage imageNamed:@"dragBallMiddle"];
		
		float correction = 10.0;
		if (numSize.width < 10) {
			correction = numSize.width;
		}
		
		badge = [[[NSImage alloc] initWithSize:NSMakeSize([ballLeft size].width + [ballRight size].width + numSize.width - correction, [ballLeft size].height)] autorelease];
		[badge lockFocus];
		
		NSDrawThreePartImage(NSMakeRect(0.0, 0.0, badge.size.width, badge.size.height),
							 ballLeft, 
							 ballMiddle, 
							 ballRight, 
							 NO, 
							 NSCompositeSourceOver,
							 1.0,
							 NO);
		
		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowColor:[NSColor blackColor]];
		[shadow setShadowBlurRadius:1.0];
		[shadow setShadowOffset:NSMakeSize(1.0, -1.0)];
		[shadow set];
		
		[label drawInRect:NSMakeRect(0.0, -4.0, [badge size].width, [badge size].height)
		   withAttributes:attributes];
		
		[badge unlockFocus];
	}
	
	NSSize decoratedImageSize = mosaic.size;
	
	if (badge != nil) {
		decoratedImageSize.width += badge.size.width;
		decoratedImageSize.height += badge.size.height;
	}
	
	NSImage *decoratedMosaic = [[[NSImage alloc] initWithSize:decoratedImageSize] autorelease];
	[decoratedMosaic lockFocus];
	
	[mosaic drawAtPoint:NSMakePoint((decoratedImageSize.width / 2) - (mosaic.size.width / 2), 
									(decoratedImageSize.height / 2) - (mosaic.size.height / 2))
			   fromRect:NSZeroRect
			  operation:NSCompositeSourceOver
			   fraction:1.0];
	
	if (badge != nil) {
		[badge drawAtPoint:NSMakePoint(decoratedImageSize.width - badge.size.width,
									   0.0)
				  fromRect:NSZeroRect
				 operation:NSCompositeSourceOver
				  fraction:1.0];
	}
	
	[decoratedMosaic unlockFocus];
	
	return decoratedMosaic;
}


@end
