//
//  CoCAAudioDevice.h
//  SoundCast
//
//  Created by Joachim Bengtsson on 2007-04-08.
//  Copyright 2007 Joachim Bengtsson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <CoreAudio/CoreAudio.h>
#include <CoreFoundation/CoreFoundation.h>

#import "CoCAAudioHardwareSystem.h"


@interface CoCAAudioDevice : NSObject {
    AudioDeviceID adid;
}
+(NSArray*)inputDevices;
+(NSArray*)outputDevices;
+(NSArray*)allDevices;
+(CoCAAudioDevice*)namedDevice:(NSString*)name;
+(CoCAAudioDevice*)defaultInput;
+(CoCAAudioDevice*)defaultOutput;
-(void) setAsDefaultInput;
-(void) setAsDefaultOutput;



-(AudioDeviceID)audioDeviceID;

-(NSString*)name;

-(unsigned)streamCountInSection:(CoCADeviceSection)sec;

@end


@interface CoCAAudioDevice (Private)
// Use the CoCAAudioHardwareSystem or CoCAAudioDevice factory methods to get devices.
-(CoCAAudioDevice*)initForID:(AudioDeviceID)aadid;
+(CoCAAudioDevice*)deviceForID:(AudioDeviceID)aadid;

-(UInt32)propertyDataSize:(AudioHardwarePropertyID)inPropertyID
               forChannel:(unsigned)chan
                inSection:(CoCADeviceSection)sec;
-(void)property:(AudioHardwarePropertyID)inPropertyID
     forChannel:(unsigned)chan
      inSection:(CoCADeviceSection)sec
           size:(UInt32)ioDataSize
           data:(void*)outData;
-(void)setProperty:(AudioHardwarePropertyID)inPropertyID
        forChannel:(unsigned)chan
         inSection:(CoCADeviceSection)sec
              size:(UInt32)inDataSize
              data:(const void*)inData
                at:(AudioTimeStamp*)when; // NULL for now


@end
