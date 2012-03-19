//
//  VivaSidebarTableCellView.h
//  Viva
//
//  Created by Daniel Kennett on 06/02/2012.
//  For license information, see LICENSE.markdown
//

#import <AppKit/AppKit.h>

@interface VivaSidebarTableCellView : NSTableCellView

@property (nonatomic, readwrite, strong) id originalItem;
@property (nonatomic, readonly, copy) NSString *title;

@end
