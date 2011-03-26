//
//  VivaPlaylistExtensions.h
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface SPSpotifyPlaylist (VivaPlaylistExtensions)

-(NSImage *)icon;
-(NSImage *)generateMosaicImageWithImages:(NSArray *)images;

@end

@interface SPSpotifyPlaylistFolder (VivaPlaylistExtensions)

-(NSImage *)icon;

@end
