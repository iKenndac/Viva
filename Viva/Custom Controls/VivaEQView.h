//
//  VivaEQView.h
//  Viva
//
//  Created by Daniel Kennett on 03/01/2012.
//  For license information, see LICENSE.markdown
//

#import <Cocoa/Cocoa.h>
#import "VivaPlaybackManager.h"

@interface VivaEQView : NSView <NSAnimationDelegate>

@property (nonatomic, readwrite, strong) EQPreset *currentEQSettings;
-(void)setCurrentEQSettings:(EQPreset *)settings animated:(BOOL)animate;

@end
