//
//  EQCoreAudioController.h
//  Viva
//
//  Created by Daniel Kennett on 03/04/2012.
//  For license information, see LICENSE.markdown
//

#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "EQPresetController.h"
#import "iTunesPluginHost.h"

@interface VivaCoreAudioController : SPCoreAudioController <NSWindowDelegate>

@property (readwrite, strong, nonatomic) EQPreset *eqPreset;

-(IBAction)ensureVisualizerVisible:(id)sender;
-(IBAction)hideVisualizer:(id)sender;

@property (nonatomic, readonly, copy) NSArray *visualizers;
@property (nonatomic, readwrite, strong) iTunesVisualPlugin *activeVisualizer;
@property (nonatomic, readonly) BOOL visualizerVisible;

@end
