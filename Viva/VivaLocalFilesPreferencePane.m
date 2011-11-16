//
//  VivaLocalFilesPreferencePane.m
//  Viva
//
//  Created by Daniel Kennett on 15/11/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import "VivaLocalFilesPreferencePane.h"
#import "LocalFilesController.h"

@implementation VivaLocalFilesPreferencePane
@synthesize fileSourceArrayController;

-(id)init {
	return [self initWithNibName:@"VivaLocalFilesPreferencePane" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
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
