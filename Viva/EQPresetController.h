//
//  EQPresetController.h
//  Viva
//
//  Created by Daniel Kennett on 04/01/2012.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EQPreset : NSObject <NSCopying>

-(id)initWithPlistValue:(NSDictionary *)plist;
-(NSDictionary *)plistValue;

@property (nonatomic, readwrite) double band1;
@property (nonatomic, readwrite) double band2;
@property (nonatomic, readwrite) double band3;
@property (nonatomic, readwrite) double band4;
@property (nonatomic, readwrite) double band5;
@property (nonatomic, readwrite) double band6;
@property (nonatomic, readwrite) double band7;
@property (nonatomic, readwrite) double band8;
@property (nonatomic, readwrite) double band9;
@property (nonatomic, readwrite) double band10;
@property (nonatomic, readwrite, copy) NSString *name;

@end

@interface EQPresetController : NSObject

+(EQPresetController *)sharedInstance;

@property (nonatomic, readonly, copy) NSArray *builtInPresets;
@property (nonatomic, readonly, copy) EQPreset *blankPreset;
@property (nonatomic, readonly, copy) NSArray *customPresets;
@property (nonatomic, readonly, retain) EQPreset *unnamedCustomPreset;

-(void)addCustomPreset:(EQPreset *)aPreset;
-(void)removeCustomPreset:(EQPreset *)aPreset;

@end
