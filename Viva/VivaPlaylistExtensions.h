//
//  VivaPlaylistExtensions.h
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface SPPlaylist (VivaPlaylistExtensions)

-(NSImage *)icon;
-(NSImage *)generatePlaylistImage;

@end

@interface SPPlaylistFolder (VivaPlaylistExtensions)

-(NSImage *)icon;

@end
