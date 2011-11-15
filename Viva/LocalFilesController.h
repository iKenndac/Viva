//
//  LocalFilesController.h
//  Viva
//
//  Created by Daniel Kennett on 15/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "LocalFile.h"
#import "LocalFileSource.h"

@interface LocalFilesController : NSObject

+(LocalFilesController *)sharedInstance;

-(LocalFileSource *)addLocalFileSourceAtPath:(NSString *)path;
-(void)removeLocalFileSource:(LocalFileSource *)source;

-(NSArray *)localFileSources;

-(LocalFile *)localFileForTrack:(SPTrack *)track;

@end
