//
//  VivaClickableArtistTableCellView.m
//  Viva
//
//  Created by Daniel Kennett on 04/04/2012.
//  For license information, see LICENSE.markdown
//

#import "VivaClickableArtistTableCellView.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "VivaLinkTextField.h"

@implementation VivaClickableArtistTableCellView

-(id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	
	if (self) {
		[self addObserver:self forKeyPath:@"objectValue.track.loaded" options:0 context:nil];
	}
	
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	
	if (self) {
		[self addObserver:self forKeyPath:@"objectValue.track.loaded" options:0 context:nil];
	}
	
	return self;
}

@synthesize linkField;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"objectValue.track.loaded"]) {
        
		SPTrack *track = (SPTrack *)[self.objectValue track];
		
		NSMutableArray *items = [NSMutableArray array];
		
		for (SPArtist *artist in track.artists) {
			
			NSURL *url = artist.spotifyURL;
			if ([url.absoluteString isEqualToString:@"spotify:artist:0000000000000000000000"])
				url = nil;
			
			[items addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							  artist.name, kVivaLinkViewItemTitleKey,
							  url, kVivaLinkViewItemKey, nil]];
			
		}
		
		[(VivaLinkTextField *)self.linkField setItems:items];
		
		
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"objectValue.track.loaded"];
}


@end
