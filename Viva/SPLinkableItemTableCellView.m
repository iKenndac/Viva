//
//  SPLinkableItemTableCellView.m
//  Viva
//
//  Created by Daniel Kennett on 01/10/2011.
//  Copyright (c) 2011 Spotify. All rights reserved.
//

#import "SPLinkableItemTableCellView.h"
#import "MainWindowController.h"
#import "VivaURLNavigationController.h"

@implementation SPLinkableItemTableCellView

-(id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        
        NSNib *nib = [[NSNib alloc] initWithNibNamed:@"SPLinkableItemTableCellView" bundle:nil];
        [nib instantiateNibWithOwner:self topLevelObjects:nil];
        
        self.view.frame = self.bounds;
        [self addSubview:self.view];
        
        [self.linkButton setTarget:self];
        [self.linkButton setAction:@selector(linkButtonClicked:)];
    }
    return self;
}

-(void)dealloc {
    [self.view removeFromSuperviewWithoutNeedingDisplay];
}

-(void)setObjectValue:(id)obj {
    NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), obj);
    [super setObjectValue:obj];
}

@synthesize linkButton;
@synthesize view;

-(void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    [super setBackgroundStyle:backgroundStyle];
    [self.textField.cell setBackgroundStyle:backgroundStyle];
    [self.linkButton.cell setBackgroundStyle:backgroundStyle];
}

-(IBAction)linkButtonClicked:(id)sender {
    if ([self.objectValue respondsToSelector:@selector(spotifyURL)]) {
        ((VivaURLNavigationController *)[(MainWindowController *)self.window.windowController navigationController]).thePresent = [self.objectValue spotifyURL];
    }
}

@end
