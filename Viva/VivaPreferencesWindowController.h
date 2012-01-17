//
//  VivaPreferencesWindowController.h
//  Viva
//
//  Created by Daniel Kennett on 14/11/2011.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>

@interface VivaPreferencesWindowController : NSWindowController

@property (weak) IBOutlet NSToolbarItem *generalButton;
@property (weak) IBOutlet NSToolbarItem *lastFMButton;
@property (weak) IBOutlet NSToolbarItem *localFilesButton;

- (IBAction)switchToGeneralPane:(id)sender;
- (IBAction)switchToLastFMPane:(id)sender;
- (IBAction)switchToLocalFilesPane:(id)sender;

@end
