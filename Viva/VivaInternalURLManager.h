//
//  VivaInternalURLManager.h
//  Viva
//
//  Created by Daniel Kennett on 3/26/11.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>

@protocol VivaViewController <NSObject>

-(id)initWithObjectFromURL:(NSURL *)aURL;
-(void)viewControllerDidActivateWithContext:(id)context;

@end

@interface VivaInternalURLManager : NSObject {
@private
	
	NSMutableDictionary *prefixToClassLookupTable;
	NSMutableDictionary *urlToViewControllerLookupTable;
}

+(VivaInternalURLManager *)sharedInstance;

-(void)registerViewControllerClass:(Class)aViewControllerClass forURLScheme:(NSString *)urlSchemePrefix;

-(BOOL)canHandleURL:(NSURL *)aURL;
-(NSViewController <VivaViewController> *)viewControllerForURL:(NSURL *)aURL;


@end
