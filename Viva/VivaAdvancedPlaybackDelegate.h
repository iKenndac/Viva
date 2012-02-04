//
//  VivaAdvancedPlaybackDelegate.h
//  Viva
//
//  Created by Daniel Kennett on 03/02/2012.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@protocol VivaAdvancedPlaybackDelegate <NSObject, SPSessionPlaybackDelegate>

-(void)sessionDidEndPlayback:(id<SPSessionPlaybackProvider>)aSession withError:(NSError *)anError;

@end
