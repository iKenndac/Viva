//
//  PlaybackStats.h
//  Viva
//
//  Created by Daniel Kennett on 19/02/2013.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PlaybackStats : NSManagedObject

@property (nonatomic, retain) NSString *trackURI;
@property (nonatomic) NSDate *firstPlayed;
@property (nonatomic) NSDate *lastPlayed;
@property (nonatomic) int64_t playCount;
@property (nonatomic) int64_t skipCount;

@end
