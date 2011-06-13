//
//  LiveSearchViewController.m
//  Viva
//
//  Created by Daniel Kennett on 6/9/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "LiveSearchViewController.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "LiveSearch.h"

@implementation LiveSearchViewController
@synthesize tableView;
@synthesize gutterView;
@synthesize popover;

-(id)init {
	if ((self = [super initWithNibName:@"LiveSearchViewController" bundle:nil])) {
		[self addObserver:self
			   forKeyPath:@"representedObject.topTracks"
				  options:0
				  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"representedObject.topArtists"
				  options:0
				  context:nil];
		
		[self addObserver:self
			   forKeyPath:@"representedObject.topAlbums"
				  options:0
				  context:nil];
	}
	return self;
}

-(void)awakeFromNib {
	self.gutterView.backgroundImage = [NSImage imageNamed:@"livesearch-gutter"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath hasPrefix:@"representedObject."]) {
		[self.tableView reloadData];
		
		CGFloat tableHeight = tableView.numberOfRows * 30.0;
		// Always three dividers - adjust.
		tableHeight -= (3 * 30.0);
		tableHeight += (3 * 20.0);
		tableHeight += 8.0; // Yay magic numbers
		
		if (self.popover.contentSize.height != tableHeight)
			self.popover.contentSize = NSMakeSize(self.tableView.frame.size.width, tableHeight);
		
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	
	LiveSearch *search = self.representedObject;
	
	NSUInteger rowCount = search.topTracks.count + search.topAlbums.count + search.topArtists.count;
	rowCount += 4; // Dividers and "show all";
	
	if (search.topTracks.count == 0)
		rowCount++; // "No Matches"
	
	if (search.topAlbums.count == 0)
		rowCount++; // "No Matches"
	
	if (search.topArtists.count == 0)
		rowCount++; // "No Matches"
	
	return rowCount;
}

-(CGFloat)tableView:(NSTableView *)aTableView heightOfRow:(NSInteger)row {
	return [self tableView:aTableView isGroupRow:row] ? 10.0 : 30.0;
}

-(BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)row {
	return ![self tableView:aTableView isGroupRow:row];
}

- (BOOL)tableView:(NSTableView *)aTableView isGroupRow:(NSInteger)row {
	
	LiveSearch *search = self.representedObject;
	
	NSUInteger numberOfTrackRows = MAX(1, search.topTracks.count);
	NSUInteger numberOfArtistRows = MAX(1, search.topArtists.count);
	NSUInteger numberOfAlbumRows = MAX(1, search.topAlbums.count);
	
	return row == numberOfTrackRows || 
	row == numberOfTrackRows + numberOfArtistRows + 1 ||
	row == numberOfTrackRows + numberOfArtistRows + numberOfAlbumRows + 2;	
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	
	if ([[aTableColumn identifier] isEqualToString:@"HeaderColumn"])
		return nil;
	
	LiveSearch *search = self.representedObject;
	NSUInteger numberOfTrackRows = MAX(1, search.topTracks.count);
	NSUInteger numberOfArtistRows = MAX(1, search.topArtists.count);
	NSUInteger numberOfAlbumRows = MAX(1, search.topAlbums.count);
	
	NSMutableDictionary *objectValue = [NSMutableDictionary dictionaryWithCapacity:2];
	
	if (rowIndex < numberOfTrackRows) {
		
		if (search.topTracks.count == 0) {
			[objectValue setValue:@"No Matches" forKey:@"name"];
		} else {
			[objectValue setValue:((SPTrack *)[search.topTracks objectAtIndex:rowIndex]).album.cover forKey:@"cover"];
			[objectValue setValue:((SPTrack *)[search.topTracks objectAtIndex:rowIndex]).name forKey:@"name"];
		}
		
	} else if (rowIndex >= numberOfTrackRows + 1 && rowIndex < numberOfTrackRows + numberOfArtistRows + 1) {
		
		if (search.topArtists.count == 0) {
			[objectValue setValue:@"No Matches" forKey:@"name"];
		} else {
			[objectValue setValue:[NSImage imageNamed:@"NSUser"] forKey:@"cover.image"];
			[objectValue setValue:((SPArtist *)[search.topArtists objectAtIndex:rowIndex - numberOfTrackRows - 1]).name forKey:@"name"];
		}
	} else if (rowIndex >= numberOfTrackRows + numberOfArtistRows + 2 && rowIndex < numberOfTrackRows + numberOfArtistRows + numberOfAlbumRows + 2) {
		
		if (search.topAlbums.count == 0) {
			[objectValue setValue:@"No Matches" forKey:@"name"];
		} else {
			[objectValue setValue:((SPAlbum *)[search.topAlbums objectAtIndex:rowIndex - numberOfTrackRows - numberOfArtistRows - 2]).cover forKey:@"cover"];
			[objectValue setValue:((SPAlbum *)[search.topAlbums objectAtIndex:rowIndex - numberOfTrackRows - numberOfArtistRows - 2]).name forKey:@"name"];
		}
	} else {
		[objectValue setValue:@"Show All…" forKey:@"name"];
	}
	
	return objectValue;
}

-(void)dealloc {
	
	self.popover = nil;
	
	[self removeObserver:self
			  forKeyPath:@"representedObject.topTracks"];
	
	[self removeObserver:self
			  forKeyPath:@"representedObject.topArtists"];
	
	[self removeObserver:self
			  forKeyPath:@"representedObject.topAlbums"];
	
	[super dealloc];
}

@end
