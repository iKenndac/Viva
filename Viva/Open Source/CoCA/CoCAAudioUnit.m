//
//  CoCAAudioUnit.m
//  CoCA
//
//  Created by Joachim Bengtsson on 2008-02-10.
//  Copyright 2008 Joachim Bengtsson. All rights reserved.
//

#import "CoCAAudioUnit.h"
#import "PrivateUtil.h"


@implementation CoCAAudioUnit

#pragma mark
#pragma mark Constructors

+(CoCAAudioUnit*)unitUsingComponent:(Component)component;
{
    return [[[CoCAAudioUnit alloc] initUsingComponent:component] autorelease];
}
+(CoCAAudioUnit*)unitMatchingDescription:(ComponentDescription)description_;
{
    Component component = FindNextComponent(NULL, &description_);
    if(!component) return nil;
    
    return [CoCAAudioUnit unitUsingComponent:component];
}
+(CoCAAudioUnit*)unitBy:(OSType)manufacturer type:(OSType)type subType:(OSType)subType;
{
    ComponentDescription desc;
    desc.componentType = type;
    desc.componentSubType = subType;
    desc.componentManufacturer = manufacturer;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    return [CoCAAudioUnit unitMatchingDescription:desc];
}
+(CoCAAudioUnit*)appleUnitOfType:(OSType)type subType:(OSType)subType;
{
    return [CoCAAudioUnit unitBy:kAudioUnitManufacturer_Apple type:type subType:subType];
}

-(CoCAAudioUnit*)initUsingComponent:(Component)component_;
{
    AudioUnit unit_;
    OSErr error = OpenAComponent(component_, &unit_);

    if(error != noErr) {
        NSLog(@"-[CoCAAudioUnit initUsingComponent]: Failed to open component: %d (see file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.CoreReference.docset/Contents/Resources/Documents/documentation/Carbon/Reference/Component_Manager/Reference/reference.html#//apple_ref/doc/uid/TP30000201-CH4g-RCM0019)", error);
        return nil;
    }
    
    return [self initWrappingUnit:unit_ closeWhenDone:YES];
}
-(CoCAAudioUnit*)initWrappingUnit:(AudioUnit)unit_ closeWhenDone:(BOOL)closeWhenDone_;
{
    if ((self = [super init])) {    
		unit = unit_;
		closeWhenDone = closeWhenDone_;
    }
    return self;
}

-(void)dealloc;
{
    if(closeWhenDone) {
        AudioUnitUninitialize(unit);
        CloseComponent(unit);
    }
    [super dealloc];
}
-(void)finalize;
{
    if(closeWhenDone) {
        AudioUnitUninitialize(unit);
        CloseComponent(unit);
    }
    [super finalize];
}


+(CoCAAudioUnit*)defaultOutputUnit;
{
    return [CoCAAudioUnit appleUnitOfType:kAudioUnitType_Output subType:kAudioUnitSubType_DefaultOutput];
}


#pragma mark
#pragma mark Actions
-(void)setup;
{
    AudioUnitInitialize(unit);
}
-(void)start;
{
    AudioOutputUnitStart(unit);
}
-(void)stop;
{
    AudioOutputUnitStop(unit);
}

#pragma mark
#pragma mark Properties
-(AudioStreamBasicDescription)streamFormatForScope:(AudioUnitScope)scope;
{
    AudioStreamBasicDescription streamFormat;
    [self property:kAudioUnitProperty_StreamFormat
           inScope:scope
         inElement:0
              size:sizeof(streamFormat)
              data:&streamFormat];
    return streamFormat;
}
-(void)setStreamFormat:(AudioStreamBasicDescription)streamFormat forScope:(AudioUnitScope)scope;
{
    [self setProperty:kAudioUnitProperty_StreamFormat
              inScope:scope 
            inElement:0
                 size:sizeof(streamFormat)
                 data:&streamFormat];
}

-(void)setRenderCallback:(AURenderCallbackStruct)renderCallback;
{
    [self setProperty:kAudioUnitProperty_SetRenderCallback
              inScope:kAudioUnitScope_Input
            inElement:0
                 size:sizeof(renderCallback)
                 data:&renderCallback];
}

static OSStatus CoCAAudioUnitRenderDelegateCallback
( CoCAAudioUnit *  				audioUnit,
  AudioUnitRenderActionFlags *	ioActionFlags,
  const AudioTimeStamp *		inTimeStamp,
  UInt32						inBusNumber,
  UInt32						inNumberFrames,
  AudioBufferList *				ioData)
{
    return
        [audioUnit->renderDelegate audioUnit:audioUnit
                             renderWithFlags:ioActionFlags
                                          at:inTimeStamp
                                       onBus:inBusNumber
                                  frameCount:inNumberFrames
                                   audioData:ioData];
}

-(void)setRenderDelegate:(id<CoCAAudioUnitRenderDelegate>)renderDelegate_
{
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = (AURenderCallback)CoCAAudioUnitRenderDelegateCallback;
    callbackStruct.inputProcRefCon = self;
    self->renderDelegate = renderDelegate_;
    [self setRenderCallback:callbackStruct];
}

-(AudioUnit)audioUnit;
{
    return unit;
}

#pragma mark
#pragma mark Primitives
-(UInt32)propertyDataSize:(AudioUnitPropertyID)property
                  inScope:(AudioUnitScope)scope
                inElement:(AudioUnitElement)element;

{
	UInt32 size = 0;
	OSStatus err = AudioUnitGetPropertyInfo(unit, property, scope, element, &size, NULL);
	ThrowIfError(err, CAException(err), "CoCAAudioUnit::GetPropertyInfo: got an error getting info about a property");
	return size;
}
-(void)property:(AudioUnitPropertyID)property
        inScope:(AudioUnitScope)scope
      inElement:(AudioUnitElement)element
           size:(UInt32)size
           data:(void*)data;
{
	OSStatus err = AudioUnitGetProperty(unit, property, scope, element, data, &size);
	ThrowIfError(err, CAException(err), "CoCAAudioUnit::GetPropertyData: got an error getting the value of a property");   
}
-(void)setProperty:(AudioUnitPropertyID)property
           inScope:(AudioUnitScope)scope
         inElement:(AudioUnitElement)element
              size:(UInt32)size
              data:(const void*)data;
{
	OSStatus err = AudioUnitSetProperty(unit, property, scope, element, data, size);
	ThrowIfError(err, CAException(err), "CoCAAudioUnit::SetPropertyData: got an error setting the value of a property");
}

-(NSString*)description;
{
    NSMutableString *desc = [[sf(@"<CoCAAudioUnit@%p with input format:\n", self) mutableCopy] autorelease];
    [desc appendString:[ASBF2Dict([self streamFormatForScope:kAudioUnitScope_Input]) description]];
    [desc appendString:@"\nOutput format:\n"];
    [desc appendString:[ASBF2Dict([self streamFormatForScope:kAudioUnitScope_Output]) description]];
    [desc appendString:@">"];
    return desc;
}

@end
