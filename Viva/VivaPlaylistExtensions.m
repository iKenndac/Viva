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
		
		NSImage *generatedImage = [self generateMosaicImageWithImages:imagesWeCanUse];
		
		if (generatedImage == nil) {
			// TODO: Return "no image" image
			return nil;
		} else {
			return generatedImage;
		}
	}
}

static const double kMosaicImageSize = 300.0;

-(NSImage *)generateMosaicImageWithImages:(NSArray *)images {
	
	NSImage *mosaicImage = [[NSImage alloc] initWithSize:NSMakeSize(kMosaicImageSize, kMosaicImageSize)];
	[mosaicImage lockFocus];
	
	NSUInteger mosaicEdgeCount = floor(sqrt((double)[images count]));
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

@implementation SPSpotifyPlaylistFolder (VivaPlaylistExtensions)

-(NSImage *)icon {
	NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:@"/tmp"];
	[image setSize:NSMakeSize(32.0, 32.0)];
	return image;
}

@end
