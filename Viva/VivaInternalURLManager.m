//
//  VivaInternalURLManager.m
//  Viva
//
//  Created by Daniel Kennett on 3/26/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaInternalURLManager.h"

@implementation VivaInternalURLManager

static VivaInternalURLManager *sharedInstance;

+(VivaInternalURLManager *)sharedInstance {
	if (sharedInstance == nil) {
		sharedInstance = [[VivaInternalURLManager alloc] init]; 
	}
	
	return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
		prefixToClassLookupTable = [[NSMutableDictionary alloc] init];
		urlToViewControllerLookupTable = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

-(void)registerViewControllerClass:(Class)aViewControllerClass forURLScheme:(NSString *)urlSchemePrefix {
	
	if ([aViewControllerClass instancesRespondToSelector:@selector(initWithObjectFromURL:)]) {
		[prefixToClassLookupTable setObject:aViewControllerClass forKey:urlSchemePrefix];
	} 
}

-(NSViewController *)viewControllerForURL:(NSURL *)aURL {
	
	if ([urlToViewControllerLookupTable objectForKey:aURL] != nil) {
		return [urlToViewControllerLookupTable objectForKey:aURL];
	}
	
	for (NSString *prefix in prefixToClassLookupTable) {
		
		if ([[aURL absoluteString] hasPrefix:prefix]) {
			
			Class controllerClass = [prefixToClassLookupTable objectForKey:prefix];
			
			NSViewController *newController = [(id <VivaViewController>)[controllerClass alloc] initWithObjectFromURL:aURL];
			if (newController != nil) {
				[urlToViewControllerLookupTable setObject:newController
												   forKey:aURL];
				return [newController autorelease];
				
			}
		}
	}
	return nil;
}

- (void)dealloc {
	[prefixToClassLookupTable release];
	[urlToViewControllerLookupTable release];
    [super dealloc];
}

@end
