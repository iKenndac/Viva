//
//  VivaPlaybackProvider.h
//  Viva
//
//  Created by Daniel Kennett on 04/02/2012.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>

@protocol VivaPlaybackProvider <NSObject>

@property (readonly, strong) NSDictionary *decoderStatistics;

@end
