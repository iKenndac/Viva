//
//  SPPlaylistDelegateProxy.h
//  Viva
//
//  Created by Daniel Kennett on 11/3/11.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface SPPlaylistDelegateProxy : NSObject <SPPlaylistDelegate>

-(id)initWithProxyReceiver:(id <SPPlaylistDelegate>)receiver;

@property (readwrite, nonatomic, assign) __unsafe_unretained id <SPPlaylistDelegate> receiver; 

@end
