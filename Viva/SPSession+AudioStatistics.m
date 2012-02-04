//
//  SPSession+AudioStatistics.m
//  Viva
//
//  Created by Daniel Kennett on 04/02/2012.
//  For license information, see LICENSE.markdown
//

#import "SPSession+AudioStatistics.h"
#import <objc/runtime.h>

@implementation SPSession (AudioStatistics)

static const void *audioStatsKey = @"audioStats";

-(NSDictionary *)decoderStatistics {
	return objc_getAssociatedObject(self, audioStatsKey);
}

-(void)setDecoderStatistics:(NSDictionary *)audioStatistics {
	objc_setAssociatedObject(self, audioStatsKey, audioStatistics, OBJC_ASSOCIATION_RETAIN);
}

@end
