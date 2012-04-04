//
//  VivaClickableTextField.h
//  Viva
//
//  Created by Daniel Kennett on 04/04/2012.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>
#import "VivaLinkTextField.h"

@interface VivaClickableAlbumTableCellView : NSTableCellView

@property (nonatomic, readwrite, weak) IBOutlet VivaLinkTextField *linkField;

@end
