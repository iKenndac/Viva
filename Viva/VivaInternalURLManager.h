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

@protocol VivaWrapperViewController <NSObject>

-(void)displayItemAtURL:(NSURL *)url;

@end

@interface VivaInternalURLManager : NSObject {
@private
	
	NSMutableDictionary *prefixToClassLookupTable;
	NSMutableDictionary *urlToViewControllerLookupTable;
	NSMutableDictionary *urlToWrapperLookupTable;
}

+(VivaInternalURLManager *)sharedInstance;

-(void)registerViewControllerClass:(Class)aViewControllerClass forURLScheme:(NSString *)urlSchemePrefix;
-(void)registerHandledURL:(NSURL *)wrapperURL asWrapperForURLScheme:(NSString *)urlSchemePrefix;

-(BOOL)canHandleURL:(NSURL *)aURL;
-(NSViewController <VivaViewController> *)viewControllerForURL:(NSURL *)aURL;

-(NSViewController <VivaViewController, VivaWrapperViewController> *)wrapperViewControllerForURL:(NSURL *)aURL;

@end
