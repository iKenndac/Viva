//
//  VivaPlaylistExtensions.m
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VivaPlaylistExtensions.h"


@implementation SPSpotifyPlaylist (VivaPlaylistExtensions)

-(NSImage *)icon {
	[[NSImage imageNamed:@"local_files"] setSize:NSMakeSize(32.0, 32.0)];
	return [NSImage imageNamed:@"local_files"];
}

#pragma mark -
#pragma mark Mosaic Creation

-(NSImage *)generatePlaylistImage {
	
	if ([[self image] image] != nil) {
		return [[self image] image];
	} else {
		
		NSMutableArray *imagesWeCanUse = [NSMutableArray array];
		
		for (SPSpotifyTrack *track in [self tracks]) {
			
			SPSpotifyImage *spImage = [[track album] cover];
			
			if ([spImage image] != nil && ![imagesWeCanUse containsObject:spImage]) {
				[imagesWeCanUse addObject:spImage];
			}
		}
		
		NSUInteger mosaicEdgeCount = floor(sqrt((double)[imagesWeCanUse count]));
		NSUInteger mosaicImageCount = mosaicEdgeCount * mosaicEdgeCount;
		
		if (mosaicImageCount > 0 && mosaicImageCount <= [imagesWeCanUse count]) {
			return [self generateMosaicImageWithImages:[imagesWeCanUse objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, mosaicImageCount)]]];
		}
		
		return nil;
	}
}

static const double kMosaicImageSize = 300.0;

-(NSImage *)generateOnePartImageWithImage:(SPSpotifyImage *)anImage {
	
	NSImage *mosaicImage = [[NSImage alloc] initWithSize:NSMakeSize(kMosaicImageSize, kMosaicImageSize)];
	[mosaicImage lockFocus];
	
	[[anImage image] drawInRect:(NSRect) {
		.origin = NSMakePoint(0.0, 0.0),
		.size = [mosaicImage size]
	}
					   fromRect:NSZeroRect
					  operation:NSCompositeCopy
					   fraction:1.0];
	
	[mosaicImage unlockFocus];
	return [mosaicImage autorelease];
}

-(NSImage *)generateMosaicImageWithImages:(NSArray *)images {
	
	NSImage *mosaicImage = [[NSImage alloc] initWithSize:NSMakeSize(kMosaicImageSize, kMosaicImageSize)];
	[mosaicImage lockFocus];
	
	NSUInteger tileEdgeCount = sqrtl([images count]);
	NSSize tileSize = NSMakeSize([mosaicImage size].width / tileEdgeCount, [mosaicImage size].width / tileEdgeCount);
	
	NSUInteger imagesDrawn = 0;
	for (SPSpotifyImage *spImage in images) {
		
		[[spImage image] drawInRect:(NSRect) {
			.origin = NSMakePoint((imagesDrawn % tileEdgeCount) * tileSize.width,
								  floor(imagesDrawn / tileEdgeCount) * tileSize.height),
			.size = tileSize
		}
						   fromRect:CGRectZero
						  operation:NSCompositeCopy
						   fraction:1.0];
		
		imagesDrawn++;
	}
	
	[mosaicImage unlockFocus];
	return [mosaicImage autorelease];
}

@end

@implementation SPSpotifyPlaylistFolder (VivaPlaylistExtensions)

-(NSImage *)icon {
	NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:@"/tmp"];
	[image setSize:NSMakeSize(32.0, 32.0)];
	return image;
}

@end
