//
//  CoCAAudioHardwareSystem.h
//  SoundCast
//
//  Created by Joachim Bengtsson on 2007-04-08.
//  Copyright 2007 Joachim Bengtsson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include <CoreAudio/CoreAudio.h>
#include <CoreFoundation/CoreFoundation.h>

@class CoCAAudioDevice;

typedef enum {
    kInputDevice,
    kOutputDevice,
    kSystemDevice
} CoCADeviceSection;


@interface CoCAAudioHardwareSystem : NSObject {
}
+(unsigned)deviceCount;
+(NSArray*)devices;

+(CoCAAudioDevice*)defaultDevice:(CoCADeviceSection)type;
+(void)setDefault:(CoCADeviceSection)type device:(CoCAAudioDevice*)device;

@end

@interface CoCAAudioHardwareSystem (Private)
+(UInt32)propertyDataSize:(AudioHardwarePropertyID)inPropertyID;
+(void)property:(AudioHardwarePropertyID)inPropertyID
           size:(UInt32)ioDataSize
           data:(void*)outData;
+(void)setProperty:(AudioHardwarePropertyID)inPropertyID
              size:(UInt32)inDataSize
              data:(const void*)inData;
@end
