//
//  VivaInternalURLManager.m
//  Viva
//
//  Created by Daniel Kennett on 3/26/11.
//  For license information, see LICENSE.markdown
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
		urlToWrapperLookupTable = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

-(void)registerViewControllerClass:(Class)aViewControllerClass forURLScheme:(NSString *)urlSchemePrefix {
	
	if ([aViewControllerClass instancesRespondToSelector:@selector(initWithObjectFromURL:)]) {
		[prefixToClassLookupTable setObject:aViewControllerClass forKey:urlSchemePrefix];
	} 
}

-(void)registerHandledURL:(NSURL *)wrapperURL asWrapperForURLScheme:(NSString *)urlSchemePrefix {
	[urlToWrapperLookupTable setValue:wrapperURL forKey:urlSchemePrefix];
}

-(BOOL)canHandleURL:(NSURL *)aURL {
	
	if (aURL == nil)
		return NO;
	
	for (NSString *prefix in prefixToClassLookupTable) {
		if ([[aURL absoluteString] hasPrefix:prefix]) {
			return YES;
		}
	}
	
	return NO;
}

-(NSViewController <VivaViewController> *)viewControllerForURL:(NSURL *)aURL {
	
	if ([urlToViewControllerLookupTable objectForKey:aURL] != nil) {
		return [urlToViewControllerLookupTable objectForKey:aURL];
	}
	
	for (NSString *prefix in prefixToClassLookupTable) {
		
		if ([[aURL absoluteString] hasPrefix:prefix]) {
			
			Class controllerClass = [prefixToClassLookupTable objectForKey:prefix];
			
			NSViewController <VivaViewController> *newController = [(NSViewController <VivaViewController> *)[controllerClass alloc] initWithObjectFromURL:aURL];
			if (newController != nil) {
				[urlToViewControllerLookupTable setObject:newController
												   forKey:aURL];
				return newController;
			}
		}
	}
	return nil;
}

-(NSViewController <VivaViewController, VivaWrapperViewController> *)wrapperViewControllerForURL:(NSURL *)aURL {

	for (NSString *prefix in urlToWrapperLookupTable.allKeys) {

		if ([[aURL absoluteString] hasPrefix:prefix]) {
			NSViewController *vc = [self viewControllerForURL:[urlToWrapperLookupTable valueForKey:prefix]];
			if ([vc conformsToProtocol:@protocol(VivaWrapperViewController)])
				return (NSViewController <VivaViewController, VivaWrapperViewController> *)vc;
		}
	}
	return nil;
}


@end
