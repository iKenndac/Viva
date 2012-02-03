//
//  LocalFileSource+LocalFileSourceFLACAdditions.h
//  Viva
//
//  Created by Daniel Kennett on 03/02/2012.
//  For license information, see LICENSE.markdown
//

#import "LocalFileSource.h"

@interface LocalFileSource (LocalFileSourceFLACAdditions)

-(LocalFile *)parseMediaFileWithFLACAtPath:(NSString *)path intoContext:(NSManagedObjectContext *)context;

@end
