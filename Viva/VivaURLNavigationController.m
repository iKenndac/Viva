//
//  VivaNavigationController.m
//  Viva
//
//  Created by Daniel Kennett on 4/7/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaURLNavigationController.h"

@interface VivaURLNavigationController ()

@property (nonatomic, readwrite, copy) NSArray *thePast;
@property (nonatomic, readwrite, copy) NSArray *theFuture;
@property (nonatomic, readwrite, copy) NSString *userDefaultsKey;

@end

static NSString * const kVivaURLNavigationControllerUserDefaultsPastKey = @"thePast";
static NSString * const kVivaURLNavigationControllerUserDefaultsPresentKey = @"thePresent";
static NSString * const kVivaURLNavigationControllerUserDefaultsFutureKey = @"theFuture";

@implementation VivaURLNavigationController

-(id)init {
	return [self initWithUserDefaultsKey:nil];
}

- (id)initWithUserDefaultsKey:(NSString *)key {
    self = [super init];
    if (self) {
        // Initialization code here.
		
		self.userDefaultsKey = key;
		
		if ([key length] > 0) {
			
			NSDictionary *defaultsDict = [[NSUserDefaults standardUserDefaults] valueForKey:self.userDefaultsKey];
			
			@try {
				
				NSMutableArray *pastURLs = [NSMutableArray array];
				for (NSString *urlString in [defaultsDict valueForKey:kVivaURLNavigationControllerUserDefaultsPastKey]) {
					if ([urlString length] > 0) {
						[pastURLs addObject:[NSURL URLWithString:urlString]]; 
					}
				}
				self.thePast = [NSArray arrayWithArray:pastURLs];
				
				NSMutableArray *futureURLs = [NSMutableArray array];
				for (NSString *urlString in [defaultsDict valueForKey:kVivaURLNavigationControllerUserDefaultsFutureKey]) {
					if ([urlString length] > 0) {
						[futureURLs addObject:[NSURL URLWithString:urlString]]; 
					}
				}
				self.theFuture = [NSArray arrayWithArray:futureURLs];
				
				NSString *presentString = [defaultsDict valueForKey:kVivaURLNavigationControllerUserDefaultsPresentKey];
				if ([presentString length] > 0) {
					self.thePresent = [NSURL URLWithString:presentString];
				}
			}
			@catch (NSException *exception) {
				// If there's a problem, reset
				self.thePast = [NSArray array];
				self.theFuture = [NSArray array];
				self.thePresent = nil;
			}
			
		} else {
			self.thePast = [NSArray array];
			self.theFuture = [NSArray array];
			self.thePresent = nil;
		}
		
		[self addObserver:self
			   forKeyPath:@"thePresent"
				  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
				  context:nil];
    }
    
    return self;
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"thePresent"];
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"thePresent"]) {
        
		NSURL *previousPresent = [change valueForKey:NSKeyValueChangeOldKey];
		
		if (previousPresent == (id)[NSNull null]) 
			previousPresent = nil;
		
		if ([previousPresent isEqual:self.thePresent])
			return;
		
		if ([[self.thePast lastObject] isEqual:self.thePresent]) {
			// User went back - remove from the backwards queue and add old present to the forwards queue
			
			NSMutableArray *mutablePast = [self.thePast mutableCopy];
			[mutablePast removeObjectAtIndex:[mutablePast count] - 1];
			self.thePast = [NSArray arrayWithArray:mutablePast];

			if (previousPresent != nil) {
				self.theFuture = [[NSArray arrayWithObject:previousPresent] arrayByAddingObjectsFromArray:self.theFuture];
			}
			
		} else if ([self.theFuture count] > 0 && [[self.theFuture objectAtIndex:0] isEqual:self.thePresent]) {
			// User went forwards. Move from the forwards queue and add old present to the backwards queue. 
			
			NSMutableArray *mutableFuture = [self.theFuture mutableCopy];
			[mutableFuture removeObjectAtIndex:0];
			self.theFuture = [NSArray arrayWithArray:mutableFuture];
			
			if (previousPresent != nil) {
				self.thePast = [self.thePast arrayByAddingObject:previousPresent];
			}
			
		} else {
			// Something else! Push previous present to past and reset forwards queue.
			if (previousPresent != nil) {
				self.thePast = [self.thePast arrayByAddingObject:previousPresent];
			}
			self.theFuture = [NSArray array];
		}
		
		if ([[self userDefaultsKey] length] > 0) {
			
			NSMutableDictionary *savedState = [NSMutableDictionary dictionaryWithCapacity:3];
			[savedState setValue:[self.thePresent absoluteString] forKey:kVivaURLNavigationControllerUserDefaultsPresentKey];
			[savedState setValue:[self.thePast valueForKey:@"absoluteString"] forKey:kVivaURLNavigationControllerUserDefaultsPastKey];
			[savedState setValue:[self.theFuture valueForKey:@"absoluteString"] forKey:kVivaURLNavigationControllerUserDefaultsFutureKey];
			
			[[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithDictionary:savedState]
													 forKey:self.userDefaultsKey];
		}
		
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -

@synthesize thePast;
@synthesize theFuture;
@synthesize thePresent;
@synthesize userDefaultsKey;

+(NSSet *)keyPathsForValuesAffectingCanGoBack {
	return [NSSet setWithObject:@"thePast"];
}

-(BOOL)canGoBack {
	return [[self thePast] count] > 0;
}

+(NSSet *)keyPathsForValuesAffectingCanGoForward {
	return [NSSet setWithObject:@"theFuture"];
}

-(BOOL)canGoForward {
	return [[self theFuture] count] > 0;
}

@end
