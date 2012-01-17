//
//  VivaArtistIKImageViewProxy.h
//  Viva
//
//  Created by Daniel Kennett on 04/12/2011.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import <Quartz/Quartz.h>

@interface VivaArtistIKImageViewProxy : NSObject

-(id)initWithArtist:(SPArtist *)anArtist imageView:(IKImageBrowserView *)view;

@property (readonly, nonatomic, strong) SPArtist *artist;
@property (readwrite, nonatomic, weak) IKImageBrowserView *imageView;

@end
