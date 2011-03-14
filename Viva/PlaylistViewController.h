//
//  PlaylistViewController.h
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface SPSpotifyPlaylist (SPViewControllerCreationExtensions)

-(NSViewController *)createViewController;

@end

@interface PlaylistViewController : NSViewController {
@private

	__weak SPSpotifyPlaylist *playlist;
    
}

-(id)initWithPlaylist:(SPSpotifyPlaylist *)aPlaylist;

@property (nonatomic, readonly, retain) __weak SPSpotifyPlaylist *playlist;

@end
