//
//  SPPlaylistDelegateProxy.m
//  Viva
//
//  Created by Daniel Kennett on 11/3/11.
//  For license information, see LICENSE.markdown
//

#import "SPPlaylistDelegateProxy.h"

@implementation SPPlaylistDelegateProxy

-(id)initWithProxyReceiver:(id <SPPlaylistDelegate>)aReceiver {
	
	self = [super init];
	
	if (self) {
		self.receiver = aReceiver;
	}
	return self;
}

@synthesize receiver;

-(void)itemsInPlaylistDidUpdateMetadata:(SPPlaylist *)aPlaylist {
	if ([self.receiver respondsToSelector:_cmd])
		[self.receiver itemsInPlaylistDidUpdateMetadata:aPlaylist];
}

-(void)playlist:(SPPlaylist *)aPlaylist willRemoveItems:(NSArray *)items atIndexes:(NSIndexSet *)outgoingIndexes {
	if ([self.receiver respondsToSelector:_cmd])
		[self.receiver playlist:aPlaylist willRemoveItems:items atIndexes:outgoingIndexes];
}

-(void)playlist:(SPPlaylist *)aPlaylist didRemoveItems:(NSArray *)items atIndexes:(NSIndexSet *)theseIndexesArentValidAnymore {
	if ([self.receiver respondsToSelector:_cmd])
		[self.receiver playlist:aPlaylist didRemoveItems:items atIndexes:theseIndexesArentValidAnymore];
}

-(void)playlist:(SPPlaylist *)aPlaylist willAddItems:(NSArray *)items atIndexes:(NSIndexSet *)theseIndexesArentYetValid {
	if ([self.receiver respondsToSelector:_cmd])
		[self.receiver playlist:aPlaylist willAddItems:items atIndexes:theseIndexesArentYetValid];
}

-(void)playlist:(SPPlaylist *)aPlaylist didAddItems:(NSArray *)items atIndexes:(NSIndexSet *)newIndexes {
	if ([self.receiver respondsToSelector:_cmd])
		[self.receiver playlist:aPlaylist didAddItems:items atIndexes:newIndexes];
}

-(void)playlist:(SPPlaylist *)aPlaylist willMoveItems:(NSArray *)items atIndexes:(NSIndexSet *)oldIndexes toIndexes:(NSIndexSet *)newIndexes {
	if ([self.receiver respondsToSelector:_cmd])
		[self.receiver playlist:aPlaylist willMoveItems:items atIndexes:oldIndexes toIndexes:newIndexes];
}

-(void)playlist:(SPPlaylist *)aPlaylist didMoveItems:(NSArray *)items atIndexes:(NSIndexSet *)oldIndexes toIndexes:(NSIndexSet *)newIndexes {
	if ([self.receiver respondsToSelector:_cmd])
		[self.receiver playlist:aPlaylist didMoveItems:items atIndexes:oldIndexes toIndexes:newIndexes];
}


@end
