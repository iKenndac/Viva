//
//  VivaAlbumIKImageViewProxy.m
//  Viva
//
//  Created by Daniel Kennett on 04/12/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import "VivaAlbumIKImageViewProxy.h"
#import <Quartz/Quartz.h>

@interface VivaAlbumIKImageViewProxy ()

@property (readwrite, nonatomic, strong) SPAlbum *album;
@property (readwrite, nonatomic) NSUInteger imageVersion;

@end

@implementation VivaAlbumIKImageViewProxy

-(id)initWithAlbum:(SPAlbum *)anAlbum imageView:(IKImageBrowserView *)view {
	
	self = [super init];
	
	if (self) {
		[self addObserver:self forKeyPath:@"album.cover.image" options:0 context:nil];
		self.album = anAlbum;
		self.imageView = view;
		self.imageVersion = 1;
	}
	
	return self;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"album.cover.image"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"album.cover.image"]) {
        self.imageVersion++;
		
		[[NSRunLoop currentRunLoop] cancelPerformSelector:@selector(reloadData) target:self.imageView argument:nil];
		[self.imageView performSelector:@selector(reloadData) withObject:nil afterDelay:0.2];
		
		//[self.imageView reloadData];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@synthesize album;
@synthesize imageVersion;
@synthesize imageView;

-(NSString *)imageUID {
	return self.album.spotifyURL.absoluteString;
}

-(id)imageRepresentation {
	
	if (self.album.cover.image == nil)
		return [NSImage imageNamed:@"350-album"];
	
	return self.album.cover.image;
}

-(NSString *)imageRepresentationType {
	return IKImageBrowserNSImageRepresentationType;
}

-(NSString *)imageTitle {
	return self.album.name;
}

-(NSString *)imageSubtitle {
	return self.album.artist.name;
}

@end
