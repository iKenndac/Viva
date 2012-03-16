//
//  VivaSidebarTableCellView.m
//  Viva
//
//  Created by Daniel Kennett on 06/02/2012.
//  For license information, see LICENSE.markdown
//

#import "VivaSidebarTableCellView.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "Constants.h"

@implementation VivaSidebarTableCellView

@synthesize originalItem;

-(id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	
	if (self) {
		[self addObserver:self forKeyPath:@"objectValue" options:0 context:nil];
	}
	
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	
	if (self) {
		[self addObserver:self forKeyPath:@"objectValue" options:0 context:nil];
	}
	
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"objectValue"]) {
        self.originalItem = [self.objectValue valueForKey:SPSidebarOriginalItemKey];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

+(NSSet *)keyPathsForValuesAffectingTitle {
	return [NSSet setWithObjects:@"objectValue", @"originalItem.name", nil];
}

-(NSString *)title {
	
	NSString *aTitle = nil;
	if ([self.originalItem respondsToSelector:@selector(name)])
		aTitle = [self.originalItem name];
	
	if (aTitle == nil)
		aTitle = [self.objectValue valueForKey:SPSidebarTitleKey];
	
	return aTitle;
}

-(IBAction)nameFieldWasEdited:(id)sender {
	
	NSDictionary *itemDescriptor = [self objectValue];
	[[SPSession sharedSession] objectRepresentationForSpotifyURL:[itemDescriptor valueForKey:SPSidebarURLKey]
														callback:^(sp_linktype linkType, id objectRepresentation) {
															if ([objectRepresentation isKindOfClass:[SPPlaylist class]]) {
																[(SPPlaylist *)objectRepresentation setName:self.textField.stringValue];
															}
														}];
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"objectValue"];
}


@end
