//
//  VivaNavigationController.h
//  Viva
//
//  Created by Daniel Kennett on 4/7/11.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>


@interface VivaURLNavigationController : NSObject {
@private
	
	NSArray *thePast;
	NSURL *thePresent;
	NSArray *theFuture;
	NSString *userDefaultsKey;
}

-(id)initWithUserDefaultsKey:(NSString *)key;

@property (nonatomic, readonly, copy) NSArray *thePast;
@property (nonatomic, readwrite, copy) NSURL *thePresent;
@property (nonatomic, readonly, copy) NSArray *theFuture;

@property (nonatomic, readonly, copy) NSString *userDefaultsKey;

@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward;

@end
