//
//  EQPresetController.m
//  Viva
//
//  Created by Daniel Kennett on 04/01/2012.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "EQPresetController.h"
#import "SPArrayExtensions.h"
#import "Constants.h"

@implementation EQPreset

-(id)init {
	self = [super init];
	if (self) {
		self.name = @"Custom";
	}
	return self;
}

-(id)initWithPlistValue:(NSDictionary *)plist {
	self = [self init];
	if (self) {
		self.name = [plist valueForKey:@"name"];
		self.band1 = [[plist valueForKey:@"band1"] doubleValue];
		self.band2 = [[plist valueForKey:@"band2"] doubleValue];
		self.band3 = [[plist valueForKey:@"band3"] doubleValue];
		self.band4 = [[plist valueForKey:@"band4"] doubleValue];
		self.band5 = [[plist valueForKey:@"band5"] doubleValue];
		self.band6 = [[plist valueForKey:@"band6"] doubleValue];
		self.band7 = [[plist valueForKey:@"band7"] doubleValue];
		self.band8 = [[plist valueForKey:@"band8"] doubleValue];
		self.band9 = [[plist valueForKey:@"band9"] doubleValue];
		self.band10 = [[plist valueForKey:@"band10"] doubleValue];
	}
	return self;
}

-(id)copyWithZone:(NSZone *)zone {
	
	EQPreset *newBands = [EQPreset new];
	
	newBands.band1 = self.band1;
	newBands.band2 = self.band2;
	newBands.band3 = self.band3;
	newBands.band4 = self.band4;
	newBands.band5 = self.band5;
	newBands.band6 = self.band6;
	newBands.band7 = self.band7;
	newBands.band8 = self.band8;
	newBands.band9 = self.band9;
	newBands.band10 = self.band10;
	newBands.name = self.name;
	return newBands;
}

-(NSDictionary *)plistValue {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			self.name, @"name", 
			[NSNumber numberWithDouble:self.band1], @"band1", 
			[NSNumber numberWithDouble:self.band2], @"band2", 
			[NSNumber numberWithDouble:self.band3], @"band3", 
			[NSNumber numberWithDouble:self.band4], @"band4", 
			[NSNumber numberWithDouble:self.band5], @"band5", 
			[NSNumber numberWithDouble:self.band6], @"band6", 
			[NSNumber numberWithDouble:self.band7], @"band7", 
			[NSNumber numberWithDouble:self.band8], @"band8", 
			[NSNumber numberWithDouble:self.band9], @"band9", 
			[NSNumber numberWithDouble:self.band10], @"band10",
			nil];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"%@: %@: %1.2f, %1.2f, %1.2f, %1.2f, %1.2f, %1.2f, %1.2f, %1.2f, %1.2f",
			[super description], self.name, self.band1, self.band2, self.band3, self.band4, self.band5, 
			self.band6, self.band7, self.band8, self.band9, self.band10];
}

@synthesize band1;
@synthesize band2;
@synthesize band3;
@synthesize band4;
@synthesize band5;
@synthesize band6;
@synthesize band7;
@synthesize band8;
@synthesize band9;
@synthesize band10;
@synthesize name;

@end

@interface EQPresetController ()

@property (nonatomic, readwrite, copy) NSArray *builtInPresets;
@property (nonatomic, readwrite, copy) EQPreset *blankPreset;
@property (nonatomic, readwrite, copy) NSArray *customPresets;
@property (nonatomic, readwrite, retain) EQPreset *unnamedCustomPreset;

-(void)commitPresetsToUserDefaults;

@end

@implementation EQPresetController

static EQPresetController *sharedInstance;

+(EQPresetController *)sharedInstance {
	
	if (sharedInstance == nil)
		sharedInstance = [EQPresetController new];
	
	return sharedInstance;	
}

-(id)init {
	
	if (sharedInstance != nil)
		return sharedInstance;
	
	self = [super init];
	if (self) {
		
		// Built-Ins
		
		NSData *builtInPresetFile = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BuiltInEQPresets" ofType:@"plist"]];
		NSDictionary *builtInPresetPlists = [NSPropertyListSerialization propertyListWithData:builtInPresetFile
																				 options:0
																				  format:nil
																				   error:nil];
		
		NSMutableArray *parsedPrests = [NSMutableArray arrayWithCapacity:builtInPresetPlists.count];
		
		for (NSDictionary *plistDict in [builtInPresetPlists valueForKey:@"Presets"]) {
			EQPreset *preset = [[EQPreset alloc] initWithPlistValue:plistDict];
			if (preset)
				[parsedPrests addObject:preset];
		}
		
		self.builtInPresets = [NSArray arrayWithArray:parsedPrests];
		self.blankPreset = [[EQPreset alloc] initWithPlistValue:[builtInPresetPlists valueForKey:@"BlankPreset"]];
		
		// Customs
		
		NSMutableArray *presetsFromUserDefaults = [NSMutableArray array];
		for (NSDictionary *plistDict in [[NSUserDefaults standardUserDefaults] valueForKey:kUserEQPresetsUserDefaultsKey]) {
			EQPreset *preset = [[EQPreset alloc] initWithPlistValue:plistDict];
			if (preset)
				[presetsFromUserDefaults addObject:preset];
		}
		
		self.customPresets = [NSArray arrayWithArray:presetsFromUserDefaults];
		
		// Single
		
		NSDictionary *unsavedPreset = [[NSUserDefaults standardUserDefaults] valueForKey:kUserUnnamedEQPresetUserDefaultsKey];
		if (unsavedPreset) {
			self.unnamedCustomPreset = [[EQPreset alloc] initWithPlistValue:unsavedPreset];
		} else {
			self.unnamedCustomPreset = [EQPreset new];
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationWillTerminate:)
													 name:NSApplicationWillTerminateNotification
												   object:nil];
	}
	
	sharedInstance = self;
	return self;
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	[self commitPresetsToUserDefaults];
}

@synthesize builtInPresets;
@synthesize blankPreset;
@synthesize customPresets;
@synthesize unnamedCustomPreset;

-(void)addCustomPreset:(EQPreset *)aPreset {
	if (aPreset == nil) return;
	self.customPresets = [self.customPresets arrayByAddingObject:aPreset];
	[self commitPresetsToUserDefaults];
}

-(void)removeCustomPreset:(EQPreset *)aPreset {
	if (aPreset == nil) return;
	self.customPresets = [self.customPresets arrayByRemovingObject:aPreset];
	[self commitPresetsToUserDefaults];
}

-(void)commitPresetsToUserDefaults {
	
	NSMutableArray *plistValues = [NSMutableArray arrayWithCapacity:self.customPresets.count];
	
	for (EQPreset *preset in self.customPresets) {
		[plistValues addObject:[preset plistValue]];
	}
	
	[[NSUserDefaults standardUserDefaults] setValue:plistValues forKey:kUserEQPresetsUserDefaultsKey];
	[[NSUserDefaults standardUserDefaults] setValue:[self.unnamedCustomPreset plistValue] forKey:kUserUnnamedEQPresetUserDefaultsKey];
}

@end
