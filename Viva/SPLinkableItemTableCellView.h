//
//  SPLinkableItemTableCellView.h
//  Viva
//
//  Created by Daniel Kennett on 01/10/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface SPLinkableItemTableCellView : NSTableCellView

@property (readwrite, nonatomic, retain) IBOutlet NSButton *linkButton;
@property (readwrite, nonatomic, retain) IBOutlet NSView *view;

-(IBAction)linkButtonClicked:(id)sender;

@end
