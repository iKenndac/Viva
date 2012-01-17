//
//  VivaAlbumIKImageViewProxy.h
//  Viva
//
//  Created by Daniel Kennett on 04/12/2011.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import <Quartz/Quartz.h>

typedef enum {
	kSubtitleModeArtistName,
	kSubtitleModeYear
} ImageViewProxySubtitleMode;

@interface VivaAlbumIKImageViewProxy : NSObject

-(id)initWithAlbum:(SPAlbum *)anAlbum imageView:(IKImageBrowserView *)view;

@property (readwrite, nonatomic) ImageViewProxySubtitleMode mode;
@property (readonly, nonatomic, strong) SPAlbum *album;
@property (readwrite, nonatomic, weak) IKImageBrowserView *imageView;

@end
