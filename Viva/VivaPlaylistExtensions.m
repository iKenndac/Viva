//
//  VivaPlaylistExtensions.m
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaPlaylistExtensions.h"
#import "VivaImageExtensions.h"

@implementation SPPlaylist (VivaPlaylistExtensions)

-(NSImage *)icon {
	[[NSImage imageNamed:@"local_files"] setSize:NSMakeSize(32.0, 32.0)];
	return [NSImage imageNamed:@"local_files"];
}

-(NSImage *)generatePlaylistImage {
	
	if ([[self image] image] != nil) {
		return [[self image] image];
	} else {
		return [NSImage mosaicImageWithTracks:[self tracks]];
	}
}

-(NSArray *)playlists {
	return nil;
}

@end

@implementation SPPlaylistFolder (VivaPlaylistExtensions)

-(NSImage *)icon {
	NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:@"/tmp"];
	[image setSize:NSMakeSize(32.0, 32.0)];
	return image;
}

@end
