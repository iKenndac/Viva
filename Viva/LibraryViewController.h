//
//  LibraryViewController.h
//  Viva
//
//  Created by Daniel Kennett on 04/12/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "VivaInternalURLManager.h"
#import "SPBackgroundColorView.h"

@interface LibraryViewController : NSViewController <VivaViewController>

@property (weak) IBOutlet IKImageBrowserView *imageBrowser;

@property (nonatomic, copy, readonly) NSArray *albums;
@property (nonatomic, copy, readonly) NSArray *artists;
@property (nonatomic, readonly) BOOL showArtists;
@property (weak) IBOutlet SPBackgroundColorView *headerView;

- (IBAction)switchViews:(id)sender;

@end
