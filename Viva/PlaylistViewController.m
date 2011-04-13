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
#import "VivaSortDescriptorExtensions.h"

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

	sortAscending = YES;
	
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

#pragma mark -

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	// Either reverse the sort or change the sorting column
	
	for (NSTableColumn *col in [tableView tableColumns]) {
		if ([(SPTableHeaderCell *)[col headerCell] sortPriority] == 0) {
			if (col == tableColumn) {
				sortAscending = !sortAscending;
			}
		}
	}
	
	for (NSTableColumn *col in [tableView tableColumns]) {
		if (tableView == self.trackTable) {
			if (col == tableColumn) {
				if ([[tableColumn identifier] isEqualToString:@"title"]) {
					[self.tracksArrayController setSortDescriptors:[NSSortDescriptor trackSortDescriptorsForTitleAscending:sortAscending]];
				} else if ([[tableColumn identifier] isEqualToString:@"album"]) {
					[self.tracksArrayController setSortDescriptors:[NSSortDescriptor trackSortDescriptorsForAlbumAscending:sortAscending]];
				}
				[(SPTableHeaderCell *)[col headerCell] setSortAscending:[[[self.tracksArrayController sortDescriptors] objectAtIndex:0] ascending] priority:0];
			} else {
				[(SPTableHeaderCell *)[col headerCell] setSortAscending:YES priority:1];
			}
			
			[[self.trackTable headerView] setNeedsDisplay:YES];
		}
	}
}

- (void)dealloc {
	self.playlist = nil;
    [super dealloc];
}

@end
