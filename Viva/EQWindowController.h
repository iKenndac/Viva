//
//  EQWindowController.h
//  Viva
//
//  Created by Daniel Kennett on 03/01/2012.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VivaEQView.h"

@interface EQWindowController : NSWindowController

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

@property (weak) IBOutlet VivaEQView *eqView;

@end
