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

@interface LibraryViewController : NSViewController <VivaViewController>

@property (weak) IBOutlet IKImageBrowserView *imageBrowser;

@property (nonatomic, copy, readonly) NSArray *albums;

@end
