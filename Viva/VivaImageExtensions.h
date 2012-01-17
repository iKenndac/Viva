//
//  VivaImageExtensions.h
//  Viva
//
//  Created by Daniel Kennett on 16/04/2011.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>


@interface NSImage (VivaImageExtensions)

+(NSImage *)mosaicImageWithTracks:(NSArray *)tracks;
+(NSImage *)mosaicImageWithSPImages:(NSArray *)images;

+(NSImage *)mosaicImageWithTracks:(NSArray *)tracks aspect:(double)mosaicSideSize;
+(NSImage *)mosaicImageWithSPImages:(NSArray *)images aspect:(double)mosaicSideSize;

// Decorated

+(NSImage *)decoratedMosaicWithTracks:(NSArray *)tracks badgeLabel:(NSString *)label;
+(NSImage *)decoratedMosaicWithTracks:(NSArray *)tracks badgeLabel:(NSString *)label aspect:(double)mosaicSideSize;

@end
