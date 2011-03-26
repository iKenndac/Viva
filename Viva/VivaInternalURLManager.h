//
//  VivaInternalURLManager.h
//  Viva
//
//  Created by Daniel Kennett on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VivaViewController <NSObject>

-(id)initWithObjectFromURL:(NSURL *)aURL;

@end

@interface VivaInternalURLManager : NSObject {
@private
	
	NSMutableDictionary *prefixToClassLookupTable;
	NSMutableDictionary *urlToViewControllerLookupTable;
}

+(VivaInternalURLManager *)sharedInstance;

-(void)registerViewControllerClass:(Class)aViewControllerClass forURLScheme:(NSString *)urlSchemePrefix;

-(NSViewController *)viewControllerForURL:(NSURL *)aURL;

@end
