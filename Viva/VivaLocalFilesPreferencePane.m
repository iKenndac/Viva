//
//  VivaLocalFilesPreferencePane.m
//  Viva
//
//  Created by Daniel Kennett on 15/11/2011.
//  For license information, see LICENSE.markdown
//

#import "VivaLocalFilesPreferencePane.h"
#import "LocalFilesController.h"

@implementation VivaLocalFilesPreferencePane
@synthesize fileSourceArrayController;

-(id)init {
	return [self initWithNibName:@"VivaLocalFilesPreferencePane" bundle:nil];
}

- (IBAction)addLocalFileSource:(id)sender {
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	openPanel.canChooseDirectories = YES;
	openPanel.canChooseFiles = NO;
	
	[openPanel beginSheetModalForWindow:self.view.window
					  completionHandler:^(NSInteger result) {
						  
						  if (result == NSOKButton) {
							  NSURL *selectedURL = openPanel.URLs.lastObject;
							  LocalFileSource *source = [[LocalFilesController sharedInstance] addLocalFileSourceAtPath:selectedURL.path];
							  self.fileSourceArrayController.selectedObjects = [NSArray arrayWithObject:source];
							  [source performFullScan];
						  }
						  
					  }];
	
}

- (IBAction)removeSelectedLocalFileSource:(id)sender {
	
	if (self.fileSourceArrayController.selectedObjects.count > 0) {
		[[LocalFilesController sharedInstance] removeLocalFileSource:self.fileSourceArrayController.selectedObjects.lastObject];
	}
}

@end
