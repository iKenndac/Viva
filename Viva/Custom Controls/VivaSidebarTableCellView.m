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

-(IBAction)nameFieldWasEdited:(id)sender {
	
	NSDictionary *itemDescriptor = [self objectValue];
	id obj = [[SPSession sharedSession] objectRepresentationForSpotifyURL:[itemDescriptor valueForKey:SPSidebarURLKey]
																 linkType:NULL];
	
	if ([obj isKindOfClass:[SPPlaylist class]]) {
		[(SPPlaylist *)obj setName:self.textField.stringValue];
	}
}

@end
