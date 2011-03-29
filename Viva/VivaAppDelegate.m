//
//  VivaAppDelegate.m
//  Viva
//
//  Created by Daniel Kennett on 3/7/11.
//  Copyright 2011 Spotify. All rights reserved.
//

#import "VivaAppDelegate.h"
#import "PlaylistViewController.h"
#import "VivaInternalURLManager.h"
#import "Constants.h"

@implementation VivaAppDelegate

@synthesize window;
@synthesize session;
@synthesize audioData;
@synthesize audioUnit;

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
	
	[[VivaInternalURLManager sharedInstance] registerViewControllerClass:[PlaylistViewController class] forURLScheme:@"spotify:user"];
	
    [self setSession:[SPSpotifySession sessionWithApplicationKey:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"libspotify_appkey"
                                                                                                                                ofType:@"key"]]
                                                       userAgent:@"CocoaLibSpotify"
                                                           error:nil]];
    [[self session] setDelegate:self];
    
	mainWindowController = [[MainWindowController alloc] init];
	loginWindowController = [[LoginWindowController alloc] init];
	[loginWindowController showWindow:nil];
	
	// Playback
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(playTrack:)
												 name:kTrackShouldBePlayedNotification
											   object:nil];
}

#pragma mark -

-(void)playTrack:(NSNotification *)aNotification {
	
	@synchronized(self) {
		[self.session setIsPlaying:NO];
		[self.session unloadPlayback];
		[self.audioUnit stop];
		self.audioUnit = nil;
		
		self.audioData = [NSMutableData data];
		
		SPSpotifyTrack *track = [aNotification object];
		[self.session playTrack:track];
	}
}

#define kMaximumBytesInBuffer 1024 * 256

-(NSInteger)session:(SPSpotifySession *)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat {
	
	if (frameCount == 0)
        return 0; // Audio discontinuity, do nothing
	
	@synchronized(self) {
		
		if ([self.audioData length] >= kMaximumBytesInBuffer) {
			return 0;
		}
		
		[self.audioData appendBytes:audioFrames length:frameCount * sizeof(sint16) * audioFormat->channels];
		
		if (self.audioUnit == nil) {
			self.audioUnit = [CoCAAudioUnit defaultOutputUnit];
			[self.audioUnit setRenderDelegate:self];
			[self.audioUnit setup];
			[self.audioUnit start];
		}
		
		return frameCount;
	}
}

-(void)sessionDidEndPlayback:(SPSpotifySession *)aSession {
	@synchronized(self) {
		[self.audioUnit stop];
		self.audioUnit = nil;
	}
}

-(OSStatus)audioUnit:(CoCAAudioUnit*)audioUnit
     renderWithFlags:(AudioUnitRenderActionFlags*)ioActionFlags
                  at:(const AudioTimeStamp*)inTimeStamp
               onBus:(UInt32)inBusNumber
          frameCount:(UInt32)inNumberFrames
           audioData:(AudioBufferList *)ioData;
{
	
	@synchronized(self) {
		// Core Audio generally expects audio data to be in native-endian 32-bit floating-point linear PCM format.
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSUInteger sourceByteCount = inNumberFrames * sizeof(SInt16) * ioData->mNumberBuffers;
		const void *sourceBytes = [self.audioData bytes];
		sint16 *sourceFrames = (sint16 *)sourceBytes;
		NSUInteger actualNumberOfFrames = inNumberFrames;
		
		AudioBuffer *leftBuffer = &(ioData->mBuffers[0]);
		AudioBuffer *rightBuffer = &(ioData->mBuffers[1]); 
		
		if ([self.audioData length] < sourceByteCount) {
			NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Underrun!");
			sourceByteCount = [self.audioData length];
			actualNumberOfFrames = [self.audioData length] / 4;
		}
		
		float *leftChannelBuffer = (float*)(leftBuffer->mData);
		float *rightChannelBuffer = (float*)(rightBuffer->mData);
	
		for(int sample = 0; sample < actualNumberOfFrames; sample++) {
			
			float leftSample = (float)(sourceFrames[sample * 2]);
			float destinationLeftSample = leftSample/(float)INT16_MAX;
			
			float rightSample = (float)(sourceFrames[(sample * 2) + 1]);
			float destinationRightSample = rightSample/(float)INT16_MAX;
			
			leftChannelBuffer[sample] = destinationLeftSample;
			rightChannelBuffer[sample] = destinationRightSample;
		}	
		
		leftBuffer->mDataByteSize = (UInt32)actualNumberOfFrames * 4;
		rightBuffer->mDataByteSize = (UInt32)actualNumberOfFrames * 4;
		
		[self.audioData replaceBytesInRange:NSMakeRange(0, sourceByteCount)
								  withBytes:NULL
									 length:0];
		[pool drain];
		return noErr;
		
	}
}

#pragma mark -

-(void)sessionDidLoginSuccessfully:(SPSpotifySession *)aSession; {

	[mainWindowController showWindow:nil];
	[[loginWindowController window] orderOut:nil]; 
	loginWindowController.isLoggingIn = NO;
}

-(void)session:(SPSpotifySession *)aSession didFailToLoginWithError:(NSError *)error; {
    
    [NSApp presentError:error
         modalForWindow:[loginWindowController window]
               delegate:nil
     didPresentSelector:nil
            contextInfo:nil];
	
	loginWindowController.isLoggingIn = NO;
}
    
-(void)sessionDidLogOut:(SPSpotifySession *)aSession; {}

-(void)session:(SPSpotifySession *)aSession didEncounterNetworkError:(NSError *)error; {}
-(void)session:(SPSpotifySession *)aSession didLogMessage:(NSString *)aMessage; {}
-(void)sessionDidChangeMetadata:(SPSpotifySession *)aSession; {}

-(void)session:(SPSpotifySession *)aSession recievedMessageForUser:(NSString *)aMessage; {}
-(void)sessionDidLosePlayToken:(SPSpotifySession *)aSession; {}

-(void)dealloc {
	[mainWindowController release];
	[loginWindowController release];
	self.session = nil;
	[self.audioUnit stop];
	self.audioUnit = nil;
	self.audioData = nil;
	[super dealloc];
}

@end
