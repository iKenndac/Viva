//
//  VivaTrackExtensions.h
//  Viva
//
//  Created by Daniel Kennett on 4/13/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "LocalFile.h"

@interface SPTrack (VivaTrackExtensions)

-(NSString *)condensedArtist;
-(LocalFile *)localFile;

@end
