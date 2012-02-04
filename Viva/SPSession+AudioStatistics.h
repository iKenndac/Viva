//
//  SPSession+AudioStatistics.h
//  Viva
//
//  Created by Daniel Kennett on 04/02/2012.
//  For license information, see LICENSE.markdown
//

#import "VivaPlaybackProvider.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface SPSession (AudioStatistics) <VivaPlaybackProvider>

@property (readwrite, strong) NSDictionary *decoderStatistics;

@end
