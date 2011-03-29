//
//  CoCAAudioDevice.m
//  SoundCast
//
//  Created by Joachim Bengtsson on 2007-04-08.
//  Copyright 2007 Joachim Bengtsson. All rights reserved.
//

#import "CoCAAudioDevice.h"

#import "PrivateUtil.h"

#import "CoCAAudioHardwareSystem.h"
#import "NCCommon.h"

@implementation CoCAAudioDevice
+(NSArray*)inputDevices;
{
    NSMutableArray *inputDevices = [NSMutableArray array];
    
    foreacht(CoCAAudioDevice*, device, [CoCAAudioHardwareSystem devices]) {
        if([device streamCountInSection:kInputDevice] == 0)
            continue;
        [inputDevices addObject:device];
    }
    return inputDevices;
}
+(NSArray*)outputDevices;
{
    NSMutableArray *inputDevices = [NSMutableArray array];
    
    foreacht(CoCAAudioDevice*, device, [CoCAAudioHardwareSystem devices]) {
        if([device streamCountInSection:kOutputDevice] == 0)
            continue;
        [inputDevices addObject:device];
    }
    return inputDevices;
}
+(NSArray*)allDevices;
{
    return [CoCAAudioHardwareSystem devices];
}
+(CoCAAudioDevice*)namedDevice:(NSString*)name;
{
    foreacht(CoCAAudioDevice*, device, [CoCAAudioHardwareSystem devices])
        if([[device name] isEqualToString:name])
            return device;

    return nil;
    
}
+(CoCAAudioDevice*)defaultInput;
{
    return [CoCAAudioHardwareSystem defaultDevice:kInputDevice];
}
+(CoCAAudioDevice*)defaultOutput;
{
    return [CoCAAudioHardwareSystem defaultDevice:kOutputDevice];
}

-(void) setAsDefaultInput;
{
    [CoCAAudioHardwareSystem setDefault:kInputDevice device:self];
}
-(void) setAsDefaultOutput;
{
    [CoCAAudioHardwareSystem setDefault:kOutputDevice device:self];
    [CoCAAudioHardwareSystem setDefault:kSystemDevice device:self];
}


-(CoCAAudioDevice*)initForID:(AudioDeviceID)aadid;
{
    if(! [super init] )
        return nil;
    
    adid = aadid;
    
    return self;
}
+(CoCAAudioDevice*)deviceForID:(AudioDeviceID)aadid;
{
    return [[[CoCAAudioDevice alloc] initForID:aadid] autorelease];
}

-(AudioDeviceID)audioDeviceID;
{
    return adid;
}

-(NSString*)name;
{
    CFStringRef ret = NULL;
    UInt32 size = sizeof(CFStringRef);
    [self property:kAudioDevicePropertyDeviceNameCFString
        forChannel:0
         inSection:0
              size:size
              data:&ret];
    return (NSString*)ret;
}

-(unsigned)streamCountInSection:(CoCADeviceSection)sec;
{
	UInt32 size = [self propertyDataSize:kAudioDevicePropertyStreams
                                 forChannel:0
                                  inSection:sec];
	return size / sizeof(AudioStreamID);
}


-(NSString*)description;
{
    return [NSString stringWithFormat:@"<CoCAAudioDevice '%@' (in %u, out %u): %p>", 
        [self name],
        [self streamCountInSection:kInputDevice],
        [self streamCountInSection:kOutputDevice],
        self
        ];
}


-(UInt32)propertyDataSize:(AudioHardwarePropertyID)inPropertyID
               forChannel:(unsigned)chan
                inSection:(CoCADeviceSection)sec;

{
	UInt32 theSize = 0;
	OSStatus theError = AudioDeviceGetPropertyInfo(adid, chan, sec==kInputDevice, inPropertyID, &theSize, NULL);
	ThrowIfError(theError, CAException(theError), "CAAudioHardwareDevice::GetPropertyDataSize: got an error getting info about a property");
	return theSize;
}
-(void)property:(AudioHardwarePropertyID)inPropertyID
     forChannel:(unsigned)chan
      inSection:(CoCADeviceSection)sec
           size:(UInt32)ioDataSize
           data:(void*)outData;
{
 	OSStatus theError = AudioDeviceGetProperty(adid, chan, sec==kInputDevice, inPropertyID, &ioDataSize, outData);
	ThrowIfError(theError, CAException(theError), "CAAudioHardwareDevice::GetPropertyData: got an error getting the value of a property");   
}
-(void)setProperty:(AudioHardwarePropertyID)inPropertyID
        forChannel:(unsigned)chan
         inSection:(CoCADeviceSection)sec
              size:(UInt32)inDataSize
              data:(const void*)inData
                at:(AudioTimeStamp*)when;
{
	OSStatus theError = AudioDeviceSetProperty(adid, when, chan, sec==kInputDevice, inPropertyID, inDataSize, inData);
	ThrowIfError(theError, CAException(theError), "CAAudioHardwareDevice::SetPropertyData: got an error setting the value of a property");
}

@end
