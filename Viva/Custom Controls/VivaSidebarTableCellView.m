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
	[[SPSession sharedSession] objectRepresentationForSpotifyURL:[itemDescriptor valueForKey:SPSidebarURLKey]
														callback:^(sp_linktype linkType, id objectRepresentation) {
															if ([objectRepresentation isKindOfClass:[SPPlaylist class]]) {
																[(SPPlaylist *)objectRepresentation setName:self.textField.stringValue];
															}
														}];
}

@end
