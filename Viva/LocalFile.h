//
//  LocalFile.h
//  Viva
//
//  Created by Daniel Kennett on 15/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LocalFile : NSManagedObject

@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * artist;
@property (nonatomic, retain) NSString * album;
@property (nonatomic, retain) NSDecimalNumber * duration;
@property (nonatomic, retain) NSManagedObject *source;

@end
