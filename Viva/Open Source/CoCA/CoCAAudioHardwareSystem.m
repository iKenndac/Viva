//
//  CoCAAudioHardwareSystem.m
//  SoundCast
//
//  Created by Joachim Bengtsson on 2007-04-08.
//  Copyright 2007 Joachim Bengtsson. All rights reserved.
//

#import "CoCAAudioHardwareSystem.h"
#import "CoCAAudioDevice.h"
#import "PrivateUtil.h"

@implementation CoCAAudioHardwareSystem

#pragma mark Getting devices
+(unsigned)deviceCount;
{
 	UInt32 theAnswer = [self propertyDataSize:kAudioHardwarePropertyDevices];
	theAnswer /= sizeof(AudioDeviceID);
	return theAnswer;
}
+(NSArray*)devices;
{
    NSMutableArray *ar = [NSMutableArray array];
    unsigned i;
    
    unsigned deviceCount = [CoCAAudioHardwareSystem deviceCount];
    size_t dataSize = sizeof(AudioDeviceID)*deviceCount;
    AudioDeviceID *ids = malloc(dataSize);
    
    [CoCAAudioHardwareSystem property:kAudioHardwarePropertyDevices
                                 size:(UInt32)dataSize
                                 data:ids];
    for(i = 0; i < deviceCount; i++)
        [ar addObject: [CoCAAudioDevice deviceForID:ids[i]]];
    
    free(ids);
    
    return ar;
}


#pragma mark Default device
static AudioHardwarePropertyID CoCAddt2ahdi(CoCADeviceSection section) {
    AudioHardwarePropertyID ahpd;
    switch(section) {
        case kInputDevice:
            ahpd = kAudioHardwarePropertyDefaultInputDevice;
            break;
        case kSystemDevice:
            ahpd = kAudioHardwarePropertyDefaultSystemOutputDevice;
            break;
        case kOutputDevice:
        default:
            ahpd = kAudioHardwarePropertyDefaultOutputDevice;
            break;
    }
    return ahpd;
}
    

+(CoCAAudioDevice*)defaultDevice:(CoCADeviceSection)type;
{
    AudioDeviceID adi;
    AudioHardwarePropertyID ahpd = CoCAddt2ahdi(type);
    
    [self property:ahpd
                  size:sizeof(AudioDeviceID)
                  data:&adi];
    return [CoCAAudioDevice deviceForID:adi];
}

+(void)setDefault:(CoCADeviceSection)type device:(CoCAAudioDevice*)dev;
{
    AudioHardwarePropertyID ahpd = CoCAddt2ahdi(type);
    AudioDeviceID adi = [dev audioDeviceID];
    [self setProperty:ahpd
                 size:sizeof(AudioDeviceID)
                 data:&adi];
    
}


#pragma mark Low-level property getters and setters
+(UInt32)propertyDataSize:(AudioHardwarePropertyID)inPropertyID;
{
	UInt32 theSize = 0;
	OSStatus theError = AudioHardwareGetPropertyInfo(inPropertyID, &theSize, NULL);
	ThrowIfError(theError, CAException(theError), "CAAudioHardwareSystem::GetPropertyDataSize: got an error getting info about a property");
	return theSize;
}
+(void)property:(AudioHardwarePropertyID)inPropertyID
           size:(UInt32)ioDataSize
           data:(void*)outData;
{
    OSStatus theError = AudioHardwareGetProperty(inPropertyID, &ioDataSize, outData);
	ThrowIfError(theError, CAException(theError), "CAAudioHardwareSystem::GetPropertyData: got an error getting the value of a property");

}
+(void)setProperty:(AudioHardwarePropertyID)inPropertyID
              size:(UInt32)inDataSize
              data:(const void*)inData;
{
	OSStatus theError = AudioHardwareSetProperty(inPropertyID, inDataSize, inData);
	ThrowIfError(theError, CAException(theError), "CAAudioHardwareSystem::SetPropertyData: got an error setting the value of a property");
}


@end
