//
//  VivaTrackExtensions.h
//  Viva
//
//  Created by Daniel Kennett on 4/13/11.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "LocalFile.h"

@interface SPTrack (VivaTrackExtensions)

-(NSString *)condensedArtist;
-(NSString *)condensedArtistForUIDisplay;

-(BOOL)isEnabledInUI;
-(NSColor *)uiTextColor;

-(LocalFile *)localFile;

@end
