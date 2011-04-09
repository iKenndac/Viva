//
//  PlaylistViewController.m
//  Viva
//
//  Created by Daniel Kennett on 3/14/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "PlaylistViewController.h"
#import "SPTableHeaderCell.h"
#import "SPTableCorner.h"
#import "VivaAppDelegate.h"

@interface PlaylistViewController ()

@property (nonatomic, readwrite, retain) SPSpotifyPlaylist *playlist;

@end

@implementation PlaylistViewController

-(id)initWithObjectFromURL:(NSURL *)aURL {
	if ((self = [super initWithObjectFromURL:aURL])) {
		self.playlist = [[(VivaAppDelegate *)[NSApp delegate] session] playlistForURL:aURL];
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
	
	[self.trackTable setTarget:self];
	[self.trackTable setDoubleAction:@selector(playTrack:)];
}

-(IBAction)playTrack:(id)sender {
	if ([self.trackTable clickedRow] > -1) {
		SPSpotifyTrack *track = [[self.tracksArrayController arrangedObjects] objectAtIndex:[self.trackTable clickedRow]];
		[self playTrackInThisContext:track];
	}
}

+(NSSet *)keyPathsForValuesAffectingTracksForPlayback {
	return [NSSet setWithObject:@"tracksArrayController.arrangedObjects"];
}

-(NSArray *)tracksForPlayback {
	return [NSArray arrayWithArray:[self.tracksArrayController arrangedObjects]];
}

@synthesize tracksArrayController;
@synthesize trackTable;
@synthesize playlist;

- (void)dealloc {
	self.playlist = nil;
    [super dealloc];
}

@end
