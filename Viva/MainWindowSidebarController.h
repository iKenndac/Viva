//
//  MainWindowSidebarController.h
//  Viva
//
//  Created by Daniel Kennett on 6/20/11.
//  For license information, see LICENSE.markdown
//

#import <Foundation/Foundation.h>

@interface MainWindowSidebarController : NSObject <NSOutlineViewDelegate, NSOutlineViewDataSource> {
	NSOutlineView *__weak sidebar;
	NSURL *selectedURL;
}

@property (weak) IBOutlet NSOutlineView *sidebar;
@property (readwrite, copy, nonatomic) NSURL *selectedURL;

@property (readonly, copy, nonatomic) NSArray *pinnedItems;

-(void)handleDeleteKey;

@end
