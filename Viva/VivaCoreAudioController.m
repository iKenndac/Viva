//
//  EQCoreAudioController.m
//  Viva
//
//  Created by Daniel Kennett on 03/04/2012.
//  For license information, see LICENSE.markdown
//

#import "VivaCoreAudioController.h"
#import "Constants.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>

@interface VivaCoreAudioController ()

-(void)applyBandsToEQ:(EQPreset *)preset;

@property (strong, nonatomic, readwrite) iTunesPluginHost *pluginHost;
@property (strong, nonatomic, readwrite) iTunesVisualPlugin *runningVisualizer;
@property (strong, nonatomic, readwrite) NSWindow *visualizerWindow;

@property (strong, nonatomic, readwrite) SPCircularBuffer *leftChannelVisualizerBuffer;
@property (strong, nonatomic, readwrite) SPCircularBuffer *rightChannelVisualizerBuffer;

@end

static OSStatus EQRenderCallback(void *inRefCon,
								 AudioUnitRenderActionFlags  *ioActionFlags,
								 const AudioTimeStamp        *inTimeStamp,
								 UInt32                      inBusNumber,
								 UInt32                      inNumberFrames,
								 AudioBufferList             *ioData) {

	VivaCoreAudioController *controller = (__bridge VivaCoreAudioController *)inRefCon;
	AudioUnitRenderActionFlags flags = *ioActionFlags;
	if ((flags & kAudioUnitRenderAction_PostRender) != kAudioUnitRenderAction_PostRender || controller.runningVisualizer == nil)
		return noErr;

	SPCircularBuffer *leftCircularBuffer = controller.leftChannelVisualizerBuffer;
	SPCircularBuffer *rightCircularBuffer = controller.rightChannelVisualizerBuffer;

	Float32 *leftInBuffer = ioData->mBuffers[0].mData;
	Float32 *rightInBuffer = ioData->mNumberBuffers > 1 ? ioData->mBuffers[1].mData : ioData->mBuffers[0].mData;

	if (leftInBuffer == NULL || rightInBuffer == NULL)
		return noErr;

	[controller.leftChannelVisualizerBuffer attemptAppendData:leftInBuffer ofLength:inNumberFrames * sizeof(Float32) chunkSize:sizeof(Float32)];
	[controller.rightChannelVisualizerBuffer attemptAppendData:rightInBuffer ofLength:inNumberFrames * sizeof(Float32) chunkSize:sizeof(Float32)];

	if (leftCircularBuffer.length == leftCircularBuffer.maximumLength &&
		rightCircularBuffer.length == rightCircularBuffer.maximumLength) {

		void *left = malloc(leftCircularBuffer.maximumLength);
		void *right = malloc(rightCircularBuffer.maximumLength);

		[controller.leftChannelVisualizerBuffer readDataOfLength:leftCircularBuffer.maximumLength
											 intoAllocatedBuffer:&left];

		[controller.leftChannelVisualizerBuffer readDataOfLength:rightCircularBuffer.maximumLength
											 intoAllocatedBuffer:&right];

		[leftCircularBuffer clear];
		[rightCircularBuffer clear];

		[controller.runningVisualizer pushLeftAudioBuffer:left rightAudioBuffer:right];
		// ^Todo: Thread this so a slow plugin doesn't screw up our audio output

		free(left); left = NULL;
		free(right); right = NULL;
	}

	return noErr;
}


@implementation VivaCoreAudioController {
	AUNode eqNode;
	AudioUnit eqUnit;
}

-(id)init {
	
	self = [super init];
	
	if (self) {
		
		[self addObserver:self forKeyPath:@"eqPreset" options:0 context:nil];
		[self addObserver:self forKeyPath:@"visualizersMenu" options:0 context:nil];
		
		EQPresetController *eqController = [EQPresetController sharedInstance];
		
		for (EQPreset *preset in [[[eqController.builtInPresets
									arrayByAddingObjectsFromArray:eqController.customPresets]
								   arrayByAddingObject:eqController.blankPreset]
								  arrayByAddingObject:eqController.unnamedCustomPreset]) {
			if ([preset.name isEqualToString:[[NSUserDefaults standardUserDefaults] valueForKey:kCurrentEQPresetNameUserDefaultsKey]]) {
				self.eqPreset = preset;
				break;
			}
		}

		self.leftChannelVisualizerBuffer = [[SPCircularBuffer alloc] initWithMaximumLength:512 * sizeof(Float32)];
		self.rightChannelVisualizerBuffer = [[SPCircularBuffer alloc] initWithMaximumLength:512 * sizeof(Float32)];

		self.pluginHost = [iTunesPluginHost new];
		NSString *rememberedName = [[NSUserDefaults standardUserDefaults] valueForKey:kVivaLastVisualizerNameUserDefaultsKey];
		for (iTunesVisualPlugin *plugin in self.visualizers) {
			if ([plugin.pluginName isEqualToString:rememberedName])
				self.activeVisualizer = plugin;
		}

		if (self.activeVisualizer == nil && self.visualizers.count > 0)
			self.activeVisualizer = [self.visualizers objectAtIndex:0];

	}
	
	return self;
}

-(void)dealloc {
	[self removeObserver:self forKeyPath:@"eqPreset"];
	[self removeObserver:self forKeyPath:@"visualizersMenu"];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"eqPreset"]) {
        [[NSUserDefaults standardUserDefaults] setValue:self.eqPreset.name
												 forKey:kCurrentEQPresetNameUserDefaultsKey];
		
		[self applyBandsToEQ:self.eqPreset];

	} else if ([keyPath isEqualToString:@"visualizersMenu"]) {

		[self rebuildVisualizersMenu];

    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - EQ

-(void)applyBandsToEQ:(EQPreset *)preset {
	
	if (eqUnit == NULL) return;
	
	AudioUnitSetParameter(eqUnit, 0, kAudioUnitScope_Global, 0, (Float32)preset.band1, 0);
	AudioUnitSetParameter(eqUnit, 1, kAudioUnitScope_Global, 0, (Float32)preset.band2, 0);
	AudioUnitSetParameter(eqUnit, 2, kAudioUnitScope_Global, 0, (Float32)preset.band3, 0);
	AudioUnitSetParameter(eqUnit, 3, kAudioUnitScope_Global, 0, (Float32)preset.band4, 0);
	AudioUnitSetParameter(eqUnit, 4, kAudioUnitScope_Global, 0, (Float32)preset.band5, 0);
	AudioUnitSetParameter(eqUnit, 5, kAudioUnitScope_Global, 0, (Float32)preset.band6, 0);
	AudioUnitSetParameter(eqUnit, 6, kAudioUnitScope_Global, 0, (Float32)preset.band7, 0);
	AudioUnitSetParameter(eqUnit, 7, kAudioUnitScope_Global, 0, (Float32)preset.band8, 0);
	AudioUnitSetParameter(eqUnit, 8, kAudioUnitScope_Global, 0, (Float32)preset.band9, 0);
	AudioUnitSetParameter(eqUnit, 9, kAudioUnitScope_Global, 0, (Float32)preset.band10, 0);
}

-(BOOL)connectOutputBus:(UInt32)sourceOutputBusNumber ofNode:(AUNode)sourceNode toInputBus:(UInt32)destinationInputBusNumber ofNode:(AUNode)destinationNode inGraph:(AUGraph)graph error:(NSError **)error {
	
	// Override this method to connect the source node to the destination node via an EQ node.
	
	// A description for the EQ Device
	AudioComponentDescription eqDescription;
	eqDescription.componentType = kAudioUnitType_Effect;
	eqDescription.componentSubType = kAudioUnitSubType_GraphicEQ;
	eqDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	eqDescription.componentFlags = 0;
    eqDescription.componentFlagsMask = 0;
	
	// Add the EQ node to the AUGraph
	OSStatus status = AUGraphAddNode(graph, &eqDescription, &eqNode);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't add EQ node");
		return NO;
    }
	
	// Get the EQ Audio Unit from the node so we can set bands directly later
	status = AUGraphNodeInfo(graph, eqNode, NULL, &eqUnit);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't get EQ unit");
        return NO;
    }
	
	// Init the EQ
	status = AudioUnitInitialize(eqUnit);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't init EQ!");
        return NO;
    }
	
	// Set EQ to 10-band
	status = AudioUnitSetParameter(eqUnit, 10000, kAudioUnitScope_Global, 0, 0.0, 0);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't set EQ parameter");
        return NO;
    }
	
	// Connect the output of the source node to the input of the EQ node
	status = AUGraphConnectNodeInput(graph, sourceNode, sourceOutputBusNumber, eqNode, 0);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't connect converter to eq");
        return NO;
    }
	
	// Connect the output of the EQ node to the input of the destination node, thus completing the chain.
	status = AUGraphConnectNodeInput(graph, eqNode, 0, destinationNode, destinationInputBusNumber);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't connect eq to output");
        return NO;
    }
	
	[self applyBandsToEQ:self.eqPreset];


	///// --- Connect render callback!
	// AudioUnitAddRenderNotify
	// kAudioUnitRenderAction_PostRender

	AudioUnitAddRenderNotify(eqUnit, EQRenderCallback, (__bridge void *)self);
	
	
	return YES;
}

-(void)disposeOfCustomNodesInGraph:(AUGraph)graph {

	AudioUnitRemoveRenderNotify(eqUnit, EQRenderCallback, (__bridge void *)self);
	
	// Shut down our unit.
	AudioUnitUninitialize(eqUnit);
	eqUnit = NULL;
	
	// Remove the unit's node from the graph.
	AUGraphRemoveNode(graph, eqNode);
	eqNode = 0;
}

#pragma mark - Properties

-(NSArray *)visualizers {
	return [[self.pluginHost plugins] valueForKeyPath:@"@unionOfArrays.visualizers"];
}

-(BOOL)visualizerVisible {
	return self.visualizerWindow.isVisible;
}

#pragma mark - Visualizer UI

-(IBAction)ensureVisualizerVisible:(id)sender {

	if (self.activeVisualizer != self.runningVisualizer) {
		[self.runningVisualizer deactivate];
		self.runningVisualizer = nil;
	}

	self.runningVisualizer = self.activeVisualizer;

	[self createWindow];

	if (NSEqualSizes(self.runningVisualizer.maxSize, NSZeroSize))
		self.visualizerWindow.maxSize = NSMakeSize(FLT_MAX, FLT_MAX);
	else
		self.visualizerWindow.maxSize = self.runningVisualizer.maxSize;

	self.visualizerWindow.minSize = self.runningVisualizer.minSize;
	self.visualizerWindow.title = self.runningVisualizer.pluginName;

	[self.visualizerWindow makeKeyAndOrderFront:nil];
	[self.runningVisualizer activateInView:self.visualizerWindow.contentView];

	AudioStreamBasicDescription desc;
	memset(&desc, 0, sizeof(AudioStreamBasicDescription));
	[self.runningVisualizer playbackStartedWithMetaData:nil audioFormat:desc];
}

-(void)createWindow {
	if (self.visualizerWindow != nil) return;

	self.visualizerWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0.0, 0.0, 640.0, 480.0)
														styleMask:NSResizableWindowMask | NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
														  backing:NSBackingStoreBuffered
															defer:NO];
	[self.visualizerWindow center];
	[self.visualizerWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
	[self.visualizerWindow setReleasedWhenClosed:NO];
	self.visualizerWindow.delegate = self;
}

-(IBAction)hideVisualizer:(id)sender {
	[self.visualizerWindow close];
}

-(void)rebuildVisualizersMenu {

	[self.visualizersMenu removeAllItems];

	for (iTunesVisualPlugin *plugin in self.visualizers) {
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:plugin.pluginName action:@selector(chooseVisualizer:) keyEquivalent:@""];
		item.representedObject = plugin;
		item.target = self;
		[self.visualizersMenu addItem:item];
	}

	[self updateVisualizersMenuCheckedState];
}

-(void)updateVisualizersMenuCheckedState {
	for (NSMenuItem *item in self.visualizersMenu.itemArray) {
		item.state = (item.representedObject == self.activeVisualizer) ? NSOnState : NSOffState;
	}
}

-(void)chooseVisualizer:(NSMenuItem *)item {
	self.activeVisualizer = item.representedObject;
	if (self.visualizerVisible) [self ensureVisualizerVisible:self];
	[self updateVisualizersMenuCheckedState];
	[[NSUserDefaults standardUserDefaults] setValue:self.activeVisualizer.pluginName forKey:kVivaLastVisualizerNameUserDefaultsKey];
}

#pragma mark - Window Delegates

-(void)windowWillClose:(NSNotification *)notification {
	[self.runningVisualizer deactivate];
	self.runningVisualizer = nil;
}

-(void)windowDidResize:(NSNotification *)notification {
	[self.runningVisualizer containerViewFrameChanged];
}

-(void)windowDidMove:(NSNotification *)notification {
	[self.runningVisualizer containerViewFrameChanged];
}

@end
