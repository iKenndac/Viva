//
//  VivaPlaylistExtensions.h
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface SPPlaylist (VivaPlaylistExtensions)

-(NSImage *)icon;
-(NSImage *)generatePlaylistImage;
-(NSArray *)playlists;

@end

@interface SPPlaylistFolder (VivaPlaylistExtensions)

-(NSImage *)icon;

@end
