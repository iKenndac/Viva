//
//  LocalFileSource.h
//  Viva
//
//  Created by Daniel Kennett on 15/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LocalFile;

@interface LocalFileSource : NSManagedObject

@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) LocalFile *localFiles;

@property (nonatomic, readonly) NSImage *icon;
@property (nonatomic, readonly) NSString *displayPath;

@end
