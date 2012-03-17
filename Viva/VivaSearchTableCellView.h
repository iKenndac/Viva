//
//  VivaSearchTableCellView.h
//  Viva
//
//  Created by Daniel Kennett on 17/03/2012.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>
#import "VivaSidebarTableCellView.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface VivaSearchTableCellView : VivaSidebarTableCellView

@property (nonatomic, readwrite, strong) SPImage *cover;

@end
