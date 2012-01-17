//
//  VivaLastFMPreferencePane.h
//  Viva
//
//  Created by Daniel Kennett on 14/11/2011.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>

@interface VivaLastFMPreferencePane : NSViewController

@property (weak) IBOutlet NSTextField *statusField;
@property (weak) IBOutlet NSButton *connectButton;

- (IBAction)connectOrDisconnectWithLastFM:(id)sender;

@end
