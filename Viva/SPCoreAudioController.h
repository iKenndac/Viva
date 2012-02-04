//
//  SPCoreAudioController.h
//  Viva
//
//  Created by Daniel Kennett on 04/02/2012.
//  For license information, see LICENSE.markdown
//

// This class encapsulates a Core Audio graph that includes
// an audio format converter, a graphic EQ and a standard output.
// Clients just need to set the various properties and not worry about
// the details.

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>
#import "EQPresetController.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@class SPCoreAudioController;

@protocol SPCoreAudioControllerDelegate <NSObject>

-(void)coreAudioController:(SPCoreAudioController *)controller didOutputAudioOfDuration:(NSTimeInterval)audioDuration;

@end

@interface SPCoreAudioController : NSObject <SPSessionAudioDeliveryDelegate>

@property (readwrite, nonatomic) double volume;
@property (readwrite, nonatomic) BOOL audioOutputEnabled;
@property (readwrite, nonatomic) BOOL eqEnabled;
@property (readwrite, strong, nonatomic) EQPreset *eqPreset;

@property (readwrite, weak, nonatomic) id <SPCoreAudioControllerDelegate> delegate;

@property (readonly, strong, nonatomic) NSArray *leftLevels;
@property (readonly, strong, nonatomic) NSArray *rightLevels;

// -- Control --

-(void)clearAudioBuffers;

@end
