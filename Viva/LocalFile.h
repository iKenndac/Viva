//
//  LocalFile.h
//  Viva
//
//  Created by Daniel Kennett on 16/11/2011.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@class LocalFileSource;

@interface LocalFile : NSManagedObject

@property (nonatomic, retain) NSString * album;
@property (nonatomic, retain) NSString * artist;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) LocalFileSource *source;

@property (nonatomic, readonly, strong) SPTrack *track;

@end
