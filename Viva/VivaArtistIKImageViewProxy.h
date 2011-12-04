//
//  VivaArtistIKImageViewProxy.h
//  Viva
//
//  Created by Daniel Kennett on 04/12/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import <Quartz/Quartz.h>

@interface VivaArtistIKImageViewProxy : NSObject

-(id)initWithArtist:(SPArtist *)anArtist imageView:(IKImageBrowserView *)view;

@property (readonly, nonatomic, strong) SPArtist *artist;
@property (readwrite, nonatomic, weak) IKImageBrowserView *imageView;

@end
