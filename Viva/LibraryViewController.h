//
//  LibraryViewController.h
//  Viva
//
//  Created by Daniel Kennett on 04/12/2011.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "VivaInternalURLManager.h"
#import "SPBackgroundColorView.h"

@interface LibraryViewController : NSViewController <VivaViewController>

@property (weak) IBOutlet IKImageBrowserView *imageBrowser;

@property (nonatomic, copy, readonly) NSArray *albumProxies;
@property (nonatomic, copy, readonly) NSArray *artistProxies;
@property (nonatomic, readonly) BOOL showArtists;
@property (weak) IBOutlet SPBackgroundColorView *headerView;

- (IBAction)switchViews:(id)sender;

@end
