//
//  VivaPlaylistExtensions.m
//  Viva
//
//  Created by Daniel Kennett on 3/22/11.
//  For license information, see LICENSE.markdown
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
		
		NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:self.items.count];
		
		for (SPPlaylistItem *anItem in self.items) {
			if (anItem.itemClass == [SPTrack class])
				[tracks addObject:anItem.item];
		}
		
		return [NSImage mosaicImageWithTracks:tracks];
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

-(NSArray *)items {
	return [self.playlists valueForKeyPath:@"@unionOfArrays.items"];
}

@end
