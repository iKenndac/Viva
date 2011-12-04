//
//  VivaAlbumIKImageViewProxy.h
//  Viva
//
//  Created by Daniel Kennett on 04/12/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import <Quartz/Quartz.h>

@interface VivaAlbumIKImageViewProxy : NSObject

-(id)initWithAlbum:(SPAlbum *)anAlbum imageView:(IKImageBrowserView *)view;

@property (readonly, nonatomic, strong) SPAlbum *album;
@property (readwrite, nonatomic, weak) IKImageBrowserView *imageView;

@end
