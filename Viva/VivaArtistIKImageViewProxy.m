//
//  VivaArtistIKImageViewProxy.m
//  Viva
//
//  Created by Daniel Kennett on 04/12/2011.
//  For license information, see LICENSE.markdown
//

#import "VivaArtistIKImageViewProxy.h"
#import <Quartz/Quartz.h>

@interface VivaArtistIKImageViewProxy ()

@property (readwrite, nonatomic, strong) SPArtist *artist;
@property (readwrite, nonatomic) NSUInteger imageVersion;
@property (readwrite, nonatomic, strong) SPArtistBrowse *browse;

@end

@implementation VivaArtistIKImageViewProxy

-(id)initWithArtist:(SPArtist *)anArtist imageView:(IKImageBrowserView *)view {
	
	self = [super init];
	
	if (self) {
		[self addObserver:self forKeyPath:@"browse.firstPortrait.image" options:0 context:nil];
		self.artist	= anArtist;
		self.imageView = view;
		self.imageVersion = 1;
		
		self.browse = [[SPArtistBrowse alloc] initWithArtist:self.artist
												   inSession:[SPSession sharedSession]
														type:SP_ARTISTBROWSE_NO_ALBUMS];
	}
	
	return self;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"browse.firstPortrait.image"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"browse.firstPortrait.image"]) {
        self.imageVersion++;
		
		[[NSRunLoop currentRunLoop] cancelPerformSelector:@selector(reloadData) target:self.imageView argument:nil];
		[self.imageView performSelector:@selector(reloadData) withObject:nil afterDelay:0.2];
		
		//[self.imageView reloadData];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@synthesize browse;
@synthesize artist;
@synthesize imageVersion;
@synthesize imageView;

-(NSString *)imageUID {
	return self.artist.spotifyURL.absoluteString;
}

-(id)imageRepresentation {
	
	if (self.browse.firstPortrait.image == nil)
		return [NSImage imageNamed:@"350-artist"];
	
	return self.browse.firstPortrait.image;
}

-(NSString *)imageRepresentationType {
	return IKImageBrowserNSImageRepresentationType;
}

-(NSString *)imageTitle {
	return self.artist.name;
}

-(NSString *)imageSubtitle {
	return @"";
}

@end
