//
//  PlaylistViewController.m
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PlaylistViewController.h"
#import "SPTableHeaderCell.h"
#import "SPTableCorner.h"

@implementation SPSpotifyPlaylist (SPViewControllerCreationExtensions)

-(NSViewController *)createViewController {
	return [[[PlaylistViewController alloc] initWithPlaylist:self] autorelease];
}

@end

@interface PlaylistViewController ()

@property (nonatomic, readwrite, retain) __weak SPSpotifyPlaylist *playlist;

@end

@implementation PlaylistViewController

-(id)initWithPlaylist:(SPSpotifyPlaylist *)aPlaylist {
	if ((self = [super initWithNibName:@"PlaylistViewController" bundle:nil])) {
		self.playlist = aPlaylist;
	}
	return self;
}

-(void)awakeFromNib {

	// No IB support for custom headers. Yay!
	
	for (NSTableColumn *column in [self.trackTable tableColumns]) {
		SPTableHeaderCell *newCell = [[[SPTableHeaderCell alloc] init] autorelease];
		[newCell setObjectValue:[[column headerCell] objectValue]];
		[column setHeaderCell:newCell];
	}
	
	[self.trackTable setCornerView:[[[SPTableCorner alloc] init] autorelease]];
	
}

@synthesize trackTable;
@synthesize playlist;

- (void)dealloc
{
	self.playlist = nil;
    [super dealloc];
}

@end
