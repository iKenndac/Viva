//
//  VivaLocalFilesPreferencePane.h
//  Viva
//
//  Created by Daniel Kennett on 15/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface VivaLocalFilesPreferencePane : NSViewController

@property (strong) IBOutlet NSArrayController *fileSourceArrayController;

- (IBAction)addLocalFileSource:(id)sender;
- (IBAction)removeSelectedLocalFileSource:(id)sender;

@end
