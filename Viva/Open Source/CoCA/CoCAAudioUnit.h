//
//  CoCAAudioUnit.h
//  CoCA
//
//  Created by Joachim Bengtsson on 2008-02-10.
//  Copyright 2008 Joachim Bengtsson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>
#import <AudioUnit/AudioUnit.h>

@class CoCAAudioUnit;
@protocol CoCAAudioUnitRenderDelegate
-(OSStatus)audioUnit:(CoCAAudioUnit*)audioUnit
     renderWithFlags:(AudioUnitRenderActionFlags*)ioActionFlags
                  at:(const AudioTimeStamp*)inTimeStamp
               onBus:(UInt32)inBusNumber
          frameCount:(UInt32)inNumberFrames
           audioData:(AudioBufferList *)ioData;
@end

@interface CoCAAudioUnit : NSObject {
    AudioUnit unit;
    BOOL closeWhenDone;
    id<CoCAAudioUnitRenderDelegate> renderDelegate;
}
#pragma mark Constructors
// These will return the first Component that matches the description.
+(CoCAAudioUnit*)unitUsingComponent:(Component)component;
+(CoCAAudioUnit*)unitMatchingDescription:(ComponentDescription)description_;
+(CoCAAudioUnit*)unitBy:(OSType)manufacturer type:(OSType)type subType:(OSType)subType;
+(CoCAAudioUnit*)appleUnitOfType:(OSType)type subType:(OSType)subType;

-(CoCAAudioUnit*)initUsingComponent:(Component)component;
-(CoCAAudioUnit*)initWrappingUnit:(AudioUnit)unit closeWhenDone:(BOOL)closeWhenDone_; // designated initializer

#pragma mark    Constructors - Common units
+(CoCAAudioUnit*)defaultOutputUnit;

#pragma mark Actions
-(void)setup; // AudioUnitInitialize
-(void)start; // AudioOutputUnitStart
-(void)stop; // AudioOutputUnitStop

#pragma mark Properties
-(AudioStreamBasicDescription)streamFormatForScope:(AudioUnitScope)scope;
-(void)setStreamFormat:(AudioStreamBasicDescription)streamFormat forScope:(AudioUnitScope)scope;

-(void)setRenderCallback:(AURenderCallbackStruct)renderCallback;
-(void)setRenderDelegate:(id<CoCAAudioUnitRenderDelegate>)renderDelegate;

-(AudioUnit)audioUnit;

@end

@interface CoCAAudioUnit (Private)
-(UInt32)propertyDataSize:(AudioUnitPropertyID)property
                  inScope:(AudioUnitScope)scope
                inElement:(AudioUnitElement)element;
-(void)property:(AudioUnitPropertyID)property
        inScope:(AudioUnitScope)scope
      inElement:(AudioUnitElement)element
           size:(UInt32)size
           data:(void*)data;
-(void)setProperty:(AudioUnitPropertyID)property
           inScope:(AudioUnitScope)scope
         inElement:(AudioUnitElement)element
              size:(UInt32)size
              data:(const void*)data;


@end

