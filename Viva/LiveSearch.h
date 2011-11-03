//
//  LiveSearch.h
//  Viva
//
//  Created by Daniel Kennett on 6/9/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface LiveSearch : NSObject

-(id)initWithInitialSearch:(SPSearch *)aSearch;
-(void)clear;

@property (nonatomic, readwrite, strong) SPSearch *latestSearch;

@property (nonatomic, readonly, copy) NSArray *topTracks;
@property (nonatomic, readonly, copy) NSArray *topArtists;
@property (nonatomic, readonly, copy) NSArray *topAlbums;

@property (nonatomic, readonly, strong) id topHit;

@end
