//
//  EQCoreAudioController.h
//  Viva
//
//  Created by Daniel Kennett on 03/04/2012.
//  For license information, see LICENSE.markdown
//

#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "EQPresetController.h"

@interface EQCoreAudioController : SPCoreAudioController

@property (readwrite, strong, nonatomic) EQPreset *eqPreset;

@end
