//
//  VivaPreferencesWindowController.h
//  Viva
//
//  Created by Daniel Kennett on 14/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VivaPreferencesWindowController : NSWindowController

@property (weak) IBOutlet NSToolbarItem *generalButton;
@property (weak) IBOutlet NSToolbarItem *lastFMButton;

- (IBAction)switchToGeneralPane:(id)sender;
- (IBAction)switchToLastFMPane:(id)sender;

@end
