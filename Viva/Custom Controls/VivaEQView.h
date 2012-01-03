//
//  VivaEQView.h
//  Viva
//
//  Created by Daniel Kennett on 03/01/2012.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VivaPlaybackManager.h"

@interface VivaEQView : NSView

@property (nonatomic, readwrite, strong) EQBands *currentEQSettings;

@end
