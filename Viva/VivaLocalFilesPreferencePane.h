//
//  VivaLocalFilesPreferencePane.h
//  Viva
//
//  Created by Daniel Kennett on 15/11/2011.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>

@interface VivaLocalFilesPreferencePane : NSViewController

@property (strong) IBOutlet NSArrayController *fileSourceArrayController;

- (IBAction)addLocalFileSource:(id)sender;
- (IBAction)removeSelectedLocalFileSource:(id)sender;

@end
