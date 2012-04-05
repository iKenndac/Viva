//
//  VivaClickableTextField.m
//  Viva
//
//  Created by Daniel Kennett on 04/04/2012.
//  For license information, see LICENSE.markdown
//

#import "VivaClickableAlbumTableCellView.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaLinkTextField.h"

@implementation VivaClickableAlbumTableCellView

-(id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	
	if (self) {
		[self addObserver:self forKeyPath:@"objectValue.track.album.loaded" options:0 context:nil];
	}
	
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	
	if (self) {
		[self addObserver:self forKeyPath:@"objectValue.track.album.loaded" options:0 context:nil];
	}
	
	return self;
}

@synthesize linkField;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"objectValue.track.album.loaded"]) {
        
		SPTrack *track = (SPTrack *)[self.objectValue track];
		
		NSURL *url = track.album.spotifyURL;
		if ([url.absoluteString isEqualToString:@"spotify:album:0000000000000000000000"])
			url = nil;
		
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  track.album.name, kVivaLinkViewItemTitleKey,
							  url, kVivaLinkViewItemKey, nil];
		
		[(VivaLinkTextField *)self.linkField setItems:[NSArray arrayWithObject:dict]];
		
		
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"objectValue.track.album.loaded"];
}



@end
