//
//  ArtistViewController.h
//  Viva
//
//  Created by Daniel Kennett on 4/24/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VivaInternalURLManager.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import <Quartz/Quartz.h>
#import "SPBackgroundColorView.h"

@interface ArtistViewController : NSViewController <VivaViewController> {
@private
    SPArtistBrowse *artistBrowse;
}

@property (weak) IBOutlet IKImageBrowserView *imageBrowser;
@property (weak) IBOutlet SPBackgroundColorView *headerView;

@property (nonatomic, readonly, strong) SPArtistBrowse *artistBrowse;
@property (nonatomic, readonly, strong) NSArray *albums;
@property (nonatomic, readonly, strong) NSArray *relatedAlbums;



@end
