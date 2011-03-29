/*
 *  PrivateUtil.h
 *  SoundCast
 *
 *  Created by Joachim Bengtsson on 2007-04-08.
 *  Copyright 2007 Joachim Bengtsson. All rights reserved.
 *
 */

#define Throw(inException)  //throw (inException)
#import "NCCommon.h"

#define ThrowIfError(inError, inException, inMessage)                                       \
{                                                                                           \
				SInt32 __Err = (inError);                                                   \
                    if(__Err != 0)															\
                    {																		\
                        char __4CC[5] = FourCC2Str(__Err);								\
                            NSLog([NSString stringWithUTF8String: "" inMessage ", Error: %ld (%s)"], __Err, __4CC);             \
                    }																		\
}

#define ASBF2Dict(inDesc) dict(@"Sample rate", num(inDesc.mSampleRate),\
                             @"Format ID", FourCCString(inDesc.mFormatID), \
                             @"Format flags", [num(inDesc.mFormatFlags) binaryRepresentation],\
                             @"Bytes per packet", num(inDesc.mBytesPerPacket),\
                             @"Frames per packet", num(inDesc.mFramesPerPacket),\
                             @"Bytes per frame", num(inDesc.mBytesPerFrame),\
                             @"Channels per frame", num(inDesc.mChannelsPerFrame),\
                             @"Bits per channel", num(inDesc.mBitsPerChannel),\
                             nil)
