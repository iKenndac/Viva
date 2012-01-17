//
//  VivaAlbumBrowseExtensions.m
//  Viva
//
//  Created by Daniel Kennett on 4/24/11.
//  For license information, see LICENSE.markdown
//

#import "VivaAlbumBrowseExtensions.h"

@implementation SPAlbumBrowse (VivaAlbumBrowseExtensions)

+(NSSet *)keyPathsForValuesAffectingCondensedCopyrights {
	return [NSSet setWithObject:@"copyrights"];
}

-(NSString *)condensedCopyrights {
	if (self.copyrights.count > 0) {
		return [self.copyrights componentsJoinedByString:@", "];
	} else {
		return nil;
	}
}

@end
