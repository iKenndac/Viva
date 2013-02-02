//
//  VisualizerController.h
//  Viva
//
//  Created by Daniel Kennett on 02/02/2013.
//  Copyright (c) 2013 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunesPluginHost.h"

@interface VisualizerController : NSObject <NSWindowDelegate>

-(IBAction)ensureVisualizerVisible:(id)sender;
-(IBAction)hideVisualizer:(id)sender;

@property (nonatomic, readonly, copy) NSArray *visualizers;
@property (nonatomic, readwrite, strong) iTunesVisualPlugin *activeVisualizer;
@property (nonatomic, readonly) BOOL visualizerVisible;

@end
