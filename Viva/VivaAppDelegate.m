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
	self.audioData = [NSData data];
}

#pragma mark -

-(void)playTrack:(NSNotification *)aNotification {
	
	[self.session setIsPlaying:NO];
	[self.session unloadPlayback];
	
	self.audioData = [NSData data];
	
	SPSpotifyTrack *track = [aNotification object];
	[self.session playTrack:track];
	
	
}

-(NSInteger)session:(SPSpotifySession *)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount format:(const sp_audioformat *)audioFormat {
	
	if (frameCount == 0)
        return 0; // Audio discontinuity, do nothing

	
	NSMutableData *data = [self.audioData mutableCopy];
	[data appendBytes:audioFrames length:frameCount * sizeof(sint16) * audioFormat->channels];
	self.audioData = data;
	
	if (unit == nil) {
		unit = [[CoCAAudioUnit defaultOutputUnit] retain];
		[unit setRenderDelegate:self];
		[unit setup];
		[unit start];
	}
	
	return frameCount;
}

-(OSStatus)audioUnit:(CoCAAudioUnit*)audioUnit
     renderWithFlags:(AudioUnitRenderActionFlags*)ioActionFlags
                  at:(const AudioTimeStamp*)inTimeStamp
               onBus:(UInt32)inBusNumber
          frameCount:(UInt32)inNumberFrames
           audioData:(AudioBufferList *)ioData;
{
	
	// Core Audio generally expects audio data to be in native-endian 32-bit floating-point linear PCM format.
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
	UInt32 sourceByteCount = inNumberFrames * 2 * ioData->mNumberBuffers;
	const void *sourceBytes = [self.audioData bytes];
	sint16 *sourceFrames = (sint16 *)sourceBytes;
	
	if ([self.audioData length] < sourceByteCount) {
		NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Underrun!");
	}
	
	AudioBuffer *leftBuffer = &(ioData->mBuffers[0]);
	AudioBuffer *rightBuffer = &(ioData->mBuffers[1]); 
	
	float *leftChannelBuffer = (float*)(leftBuffer->mData);
	float *rightChannelBuffer = (float*)(rightBuffer->mData);
	
	for(int sample = 0; sample < inNumberFrames; sample++) {
		
		float leftSample = (float)(sourceFrames[sample * 2]);
		float destinationLeftSample = leftSample/(float)INT16_MAX;
		
		float rightSample = (float)(sourceFrames[(sample * 2) + 1]);
		float destinationRightSample = rightSample/(float)INT16_MAX;
		
		leftChannelBuffer[sample] = destinationLeftSample;
		rightChannelBuffer[sample] = destinationRightSample;
	}	
	
	self.audioData = [self.audioData subdataWithRange:NSMakeRange(sourceByteCount, [self.audioData length] - sourceByteCount)];

	[pool drain];
	return noErr;


	/*
		
    for(int bufferIndex = 0; bufferIndex < ioData->mNumberBuffers; bufferIndex++) {

        AudioBuffer *buffer = &(ioData->mBuffers[bufferIndex]);
        
        float *channelBuffer = (float*)(buffer->mData);
        for(int sample = 0; sample < inNumberFrames; sample++) {
            channelBuffer[sample] = *(float *)[[audioData subdataWithRange:NSMakeRange(0, sizeof(float))] bytes];
			NSData *data = [self.audioData subdataWithRange:NSMakeRange(sizeof(float), [self.audioData length] - sizeof(float))];
			self.audioData = data;
        }
    }
	
	
	 */

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
-(void)sessionDidEndPlayback:(SPSpotifySession *)aSession; {}

-(void)dealloc {
	[mainWindowController release];
	[loginWindowController release];
	self.session = nil;
	[super dealloc];
}

@end
