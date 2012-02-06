//
//  SPTrack+LocalFileExtensions.h
//  Viva
//
//  Created by Daniel Kennett on 06/02/2012.
//  For license information, see LICENSE.markdown
//

#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "LocalFile.h"

@interface SPTrack (LocalFileExtensions)

@property (readwrite, weak, nonatomic) LocalFile *localFile;

@end
