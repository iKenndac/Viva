//
//  ArtistViewController.h
//  Viva
//
//  Created by Daniel Kennett on 4/24/11.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>
#import "VivaInternalURLManager.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import <Quartz/Quartz.h>
#import "SPBackgroundColorView.h"
#import "VivaDraggableItemImageView.h"

@interface ArtistViewController : NSViewController <VivaViewController> {
@private
    SPArtistBrowse *artistBrowse;
}

@property (weak) IBOutlet IKImageBrowserView *imageBrowser;
@property (weak) IBOutlet SPBackgroundColorView *headerView;
@property (weak) IBOutlet VivaDraggableItemImageView *artistImageView;

@property (nonatomic, readonly, strong) SPArtistBrowse *artistBrowse;
@property (nonatomic, readonly, strong) NSArray *albums;
@property (nonatomic, readonly, strong) NSArray *relatedAlbums;



@end
