//
//  VivaSearchTableCellView.m
//  Viva
//
//  Created by Daniel Kennett on 17/03/2012.
//  For license information, see LICENSE.markdown
//

#import "VivaSearchTableCellView.h"

@implementation VivaSearchTableCellView

@synthesize cover;

-(id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	
	if (self) {
		[self addObserver:self
			   forKeyPath:@"originalItem"
				  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
				  context:nil];
	}
	
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	
	if (self) {
		[self addObserver:self
			   forKeyPath:@"originalItem"
				  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
				  context:nil];
	}
	
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"originalItem"]) {
        
		id oldValue = [change valueForKey:NSKeyValueChangeOldKey];
		if (oldValue != [NSNull null] && oldValue != nil) {
			if ([oldValue isKindOfClass:[SPTrack class]])
				[oldValue removeObserver:self forKeyPath:@"album.cover"];
			else if ([oldValue isKindOfClass:[SPAlbum class]])
				[oldValue removeObserver:self forKeyPath:@"cover"];
		}
		
		if ([self.originalItem isKindOfClass:[SPTrack class]]) {
			[self.originalItem addObserver:self forKeyPath:@"album.cover" options:0 context:nil];
			self.cover = ((SPTrack *)self.originalItem).album.cover;
		} else if ([self.originalItem isKindOfClass:[SPAlbum class]]) {
			[self.originalItem addObserver:self forKeyPath:@"cover" options:0 context:nil];
			self.cover = ((SPAlbum *)self.originalItem).cover;
		} else {
			self.cover = [self.objectValue valueForKey:@"cover"];
		}
		
	} else if ([keyPath isEqualToString:@"album.cover"]) {
		self.cover = ((SPTrack *)self.originalItem).album.cover;
	} else if ([keyPath isEqualToString:@"cover"]) {
		self.cover = ((SPAlbum *)self.originalItem).cover;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)dealloc {
	self.cover = nil;
	self.originalItem = nil;
	[self removeObserver:self forKeyPath:@"originalItem"];
}

@end
