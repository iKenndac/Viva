//
//  SPCoreAudioController.m
//  Viva
//
//  Created by Daniel Kennett on 04/02/2012.
//  For license information, see LICENSE.markdown
//

#import "SPCoreAudioController.h"
#import <Accelerate/Accelerate.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SPCircularBuffer.h"
#import "Constants.h"
#import "SPSession+AudioStatistics.h"

@interface SPCoreAudioController ()

// Core Audio
-(BOOL)setupCoreAudioWithInputFormat:(AudioStreamBasicDescription)inputFormat error:(NSError **)err;
-(void)teardownCoreAudio;
-(void)startAudioQueue;
-(void)stopAudioQueue;
-(void)disableEQAudioUnit;
-(void)enableEQAudioUnit;
-(void)applyBandsToEqAudioUnit:(EQPreset *)newBands;
-(void)applyVolumeToOutputAudioUnit:(double)vol;
-(void)applyAudioStreamDescriptionToInputUnit:(AudioStreamBasicDescription)newInputDescription;

@property (readwrite, nonatomic) AudioStreamBasicDescription inputAudioDescription;

static OSStatus VivaAudioUnitRenderDelegateCallback(void *inRefCon,
                                                    AudioUnitRenderActionFlags *ioActionFlags,
                                                    const AudioTimeStamp *inTimeStamp,
                                                    UInt32 inBusNumber,
                                                    UInt32 inNumberFrames,
                                                    AudioBufferList *ioData);

//vDSP 

static void fillWithError(NSError **mayBeAnError, NSString *localizedDescription, int code);
static void performAcceleratedFastFourierTransformWithWaveform(SPCoreAudioController *controller, short *waveformArray, vDSP_Length sampleCount, double *leftDestination, double *rightDestination);
@property (readwrite, strong, nonatomic) NSArray *leftLevels;
@property (readwrite, strong, nonatomic) NSArray *rightLevels;

@property (readwrite, strong, nonatomic) SPCircularBuffer *audioBuffer;

@end

static NSTimeInterval const kTargetBufferLength = 0.5;
static NSUInteger const fftMagnitudeExponent = 4; // Must be power of two

@implementation SPCoreAudioController {
	
	AUGraph audioProcessingGraph;
	AudioUnit outputUnit;
	AudioUnit eqUnit;
	AudioUnit inputConverterUnit;
	
	AUNode outputNode;
	AUNode inputConverterNode;
	AUNode eqNode;
    
	// vDSP
	FFTSetupD fft_weights;
	double *leftChannelMagnitudes;
	double *rightChannelMagnitudes;
	
	NSMethodSignature *incrementTrackPositionMethodSignature;
	NSInvocation *incrementTrackPositionInvocation;
}

-(id)init {
	self = [super init];
	
	if (self) {
		self.volume = 1.0;
		self.eqEnabled = YES;
		self.audioOutputEnabled = NO; // Don't start audio playback until we're told.
		
		/* Setup FFT weights (twiddle factors) */
		fft_weights = vDSP_create_fftsetupD(fftMagnitudeExponent, kFFTRadix2);
		
        leftChannelMagnitudes = (double *)malloc(exp2(fftMagnitudeExponent) * sizeof(double));
        rightChannelMagnitudes = (double *)malloc(exp2(fftMagnitudeExponent) * sizeof(double));
		
		SEL incrementTrackPositionSelector = @selector(incrementTrackPositionWithFrameCount:);
		incrementTrackPositionMethodSignature = [SPCoreAudioController instanceMethodSignatureForSelector:incrementTrackPositionSelector];
		incrementTrackPositionInvocation = [NSInvocation invocationWithMethodSignature:incrementTrackPositionMethodSignature];
		[incrementTrackPositionInvocation setSelector:incrementTrackPositionSelector];
		[incrementTrackPositionInvocation setTarget:self];
		
		EQPresetController *eqController = [EQPresetController sharedInstance];
		
		[self addObserver:self forKeyPath:@"eqPreset" options:0 context:nil];
		[self addObserver:self forKeyPath:@"volume" options:0 context:nil];
		[self addObserver:self forKeyPath:@"audioOutputEnabled" options:0 context:nil];
		[self addObserver:self forKeyPath:@"eqEnabled" options:0 context:nil];
		
		for (EQPreset *preset in [[[eqController.builtInPresets
									arrayByAddingObjectsFromArray:eqController.customPresets]
								   arrayByAddingObject:eqController.blankPreset]
								  arrayByAddingObject:eqController.unnamedCustomPreset]) {
			if ([preset.name isEqualToString:[[NSUserDefaults standardUserDefaults] valueForKey:kCurrentEQPresetNameUserDefaultsKey]]) {
				self.eqPreset = preset;
				break;
			}
		}
	}
	return self;
}

-(void)dealloc {
	
	[self removeObserver:self forKeyPath:@"eqPreset"];
	[self removeObserver:self forKeyPath:@"volume"];
	[self removeObserver:self forKeyPath:@"audioOutputEnabled"];
	[self removeObserver:self forKeyPath:@"eqEnabled"];
	
	[self clearAudioBuffers];
	self.audioOutputEnabled = NO;
	[self teardownCoreAudio];
	
	// vDSP
	vDSP_destroy_fftsetupD(fft_weights);
	free(leftChannelMagnitudes);
	free(rightChannelMagnitudes);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"eqPreset"]) {
        [[NSUserDefaults standardUserDefaults] setValue:self.eqPreset.name
												 forKey:kCurrentEQPresetNameUserDefaultsKey];
		
		[self applyBandsToEqAudioUnit:self.eqPreset];
		self.eqEnabled = ![self.eqPreset isEqual:[EQPresetController sharedInstance].blankPreset];
		
    } else if ([keyPath isEqualToString:@"volume"]) {
		[self applyVolumeToOutputAudioUnit:self.volume];
		
	} else if ([keyPath isEqualToString:@"eqEnabled"]) {
		
		if (self.eqEnabled)
			[self enableEQAudioUnit];
		else
			[self disableEQAudioUnit];

	} else if ([keyPath isEqualToString:@"audioOutputEnabled"]) {
		if (self.audioOutputEnabled)
			[self startAudioQueue];
		else
			[self stopAudioQueue];
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@synthesize volume;
@synthesize eqEnabled;
@synthesize audioOutputEnabled;
@synthesize eqPreset;
@synthesize audioBuffer;

@synthesize inputAudioDescription;
@synthesize delegate;

@synthesize leftLevels;
@synthesize rightLevels;

#pragma mark -
#pragma mark CocoaLS Audio Delivery

-(NSInteger)session:(id <SPSessionPlaybackProvider>)aSession shouldDeliverAudioFrames:(const void *)audioFrames ofCount:(NSInteger)frameCount streamDescription:(AudioStreamBasicDescription)audioDescription {
	
	if (frameCount == 0) {
		[self clearAudioBuffers];
		return 0; // Audio discontinuity!
	}
	
    if (audioProcessingGraph == NULL) {
        NSError *error = nil;
        if (![self setupCoreAudioWithInputFormat:audioDescription error:&error]) {
            NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
            return 0;
        }
		
		// While we're at it, update the statistics if the audio is coming from an SPSession.
		if ([aSession isKindOfClass:[SPSession class]]) {
			
			NSDictionary *stats = [NSDictionary dictionaryWithObjectsAndKeys:
								   @"libSpotify OGG", kDecoderStatsNameKey,
								   [NSNumber numberWithDouble:audioDescription.mSampleRate], kDecoderStatsSampleRateKey,
								   [NSNumber numberWithInt:audioDescription.mBitsPerChannel], kDecoderStatsBitsPerChannelKey, 
								   nil];
			
			[(SPSession *)aSession performSelectorOnMainThread:@selector(setDecoderStatistics:)
													withObject:stats
												 waitUntilDone:NO];
		}
    }
	
	AudioStreamBasicDescription currentAudioInputDescription = self.inputAudioDescription;
	
	if (audioDescription.mBitsPerChannel != currentAudioInputDescription.mBitsPerChannel ||
		audioDescription.mBytesPerFrame != currentAudioInputDescription.mBytesPerFrame ||
		audioDescription.mChannelsPerFrame != currentAudioInputDescription.mChannelsPerFrame ||
		audioDescription.mFormatFlags != currentAudioInputDescription.mFormatFlags ||
		audioDescription.mFormatID != currentAudioInputDescription.mFormatID ||
		audioDescription.mSampleRate != currentAudioInputDescription.mSampleRate) {
		// New format. Panic!! I mean, calmly tell Core Audio that a new audio format is incoming.
		[self clearAudioBuffers];
		[self applyAudioStreamDescriptionToInputUnit:audioDescription];
		
		// While we're at it, update the statistics if the audio is coming from an SPSession.
		if ([aSession isKindOfClass:[SPSession class]]) {
			
			NSDictionary *stats = [NSDictionary dictionaryWithObjectsAndKeys:
								   @"libSpotify OGG", kDecoderStatsNameKey,
								   [NSNumber numberWithDouble:audioDescription.mSampleRate], kDecoderStatsSampleRateKey,
								   [NSNumber numberWithInt:audioDescription.mBitsPerChannel], kDecoderStatsBitsPerChannelKey, 
								   nil];
			
			[(SPSession *)aSession performSelectorOnMainThread:@selector(setDecoderStatistics:)
													withObject:stats
												 waitUntilDone:NO];
		}


	}
	
	NSUInteger dataLength = frameCount * audioDescription.mBytesPerPacket;
	
	if ((self.audioBuffer.maximumLength - self.audioBuffer.length) < dataLength) {
		// Only allow whole deliveries in, since libSpotify wants us to consume whole frames, whereas
		// the buffer works in bytes, meaning we could consume a fraction of a frame.
		return 0;
	}
	
	[self.audioBuffer attemptAppendData:audioFrames ofLength:dataLength];
	return frameCount;	
}


#pragma mark -
#pragma mark Audio Unit Properties

-(void)applyBandsToEqAudioUnit:(EQPreset *)newBands {
	
	if (audioProcessingGraph == NULL || eqUnit == NULL || newBands == nil)
		return;
	
	AudioUnitSetParameter(eqUnit, 0, kAudioUnitScope_Global, 0, (Float32)newBands.band1, 0);
	AudioUnitSetParameter(eqUnit, 1, kAudioUnitScope_Global, 0, (Float32)newBands.band2, 0);
	AudioUnitSetParameter(eqUnit, 2, kAudioUnitScope_Global, 0, (Float32)newBands.band3, 0);
	AudioUnitSetParameter(eqUnit, 3, kAudioUnitScope_Global, 0, (Float32)newBands.band4, 0);
	AudioUnitSetParameter(eqUnit, 4, kAudioUnitScope_Global, 0, (Float32)newBands.band5, 0);
	AudioUnitSetParameter(eqUnit, 5, kAudioUnitScope_Global, 0, (Float32)newBands.band6, 0);
	AudioUnitSetParameter(eqUnit, 6, kAudioUnitScope_Global, 0, (Float32)newBands.band7, 0);
	AudioUnitSetParameter(eqUnit, 7, kAudioUnitScope_Global, 0, (Float32)newBands.band8, 0);
	AudioUnitSetParameter(eqUnit, 8, kAudioUnitScope_Global, 0, (Float32)newBands.band9, 0);
	AudioUnitSetParameter(eqUnit, 9, kAudioUnitScope_Global, 0, (Float32)newBands.band10, 0);
}

-(void)applyVolumeToOutputAudioUnit:(double)vol {
    
    if (audioProcessingGraph == NULL || outputUnit == NULL)
        return;
	
    AudioUnitSetParameter(outputUnit,
                          kHALOutputParam_Volume,
                          kAudioUnitScope_Output,
                          0,
                          (vol * vol * vol),
                          0);
}

-(void)applyAudioStreamDescriptionToInputUnit:(AudioStreamBasicDescription)newInputDescription {
	
	if (audioProcessingGraph == NULL || inputConverterUnit == NULL)
		return;
	
	OSStatus status = AudioUnitSetProperty(inputConverterUnit,
								  kAudioUnitProperty_StreamFormat,
								  kAudioUnitScope_Input,
								  0,
								  &newInputDescription,
								  sizeof(newInputDescription));
	if (status != noErr) {
		NSError *error;
        fillWithError(&error, @"Couldn't set input format", status);
		NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
    } else {
		self.inputAudioDescription = newInputDescription;
		[self clearAudioBuffers];
		self.audioBuffer = [[SPCircularBuffer alloc] initWithMaximumLength:(newInputDescription.mBytesPerFrame * newInputDescription.mSampleRate) * kTargetBufferLength];
	}
}

-(void)enableEQAudioUnit {
	
	if (audioProcessingGraph == NULL || eqUnit != NULL) return;
	
	// A description for the EQ Device
	AudioComponentDescription eqDescription;
	eqDescription.componentType = kAudioUnitType_Effect;
	eqDescription.componentSubType = kAudioUnitSubType_GraphicEQ;
	eqDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	eqDescription.componentFlags = 0;
    eqDescription.componentFlagsMask = 0;
	
	OSStatus status = AUGraphAddNode(audioProcessingGraph, &eqDescription, &eqNode);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't add EQ node");
		return;
    }
	
	status = AUGraphNodeInfo(audioProcessingGraph, eqNode, NULL, &eqUnit);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't get EQ unit");
        return;
    }
	
	// Init the EQ
	status = AudioUnitInitialize(eqUnit);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't init EQ!");
        return;
    }
	
	// Set EQ to 10-band
	status = AudioUnitSetParameter(eqUnit, 10000, kAudioUnitScope_Global, 0, 0.0, 0);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't set EQ parameter");
        return;
    }
	
	// Disconnect Converter from output
	AUGraphDisconnectNodeInput(audioProcessingGraph, outputNode, 0);
	
	// Connect converter to EQ
	status = AUGraphConnectNodeInput(audioProcessingGraph, inputConverterNode, 0, eqNode, 0);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't connect converter to eq");
        return;
    }
	
	// Connect EQ node to output
	status = AUGraphConnectNodeInput(audioProcessingGraph, eqNode, 0, outputNode, 0);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't connect eq to output");
        return;
    }
	
	status = AUGraphUpdate(audioProcessingGraph, NULL);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't update graph");
        return;
    }
	
    [self applyBandsToEqAudioUnit:self.eqPreset];
}

-(void)disableEQAudioUnit {
	
	if (audioProcessingGraph == NULL || eqUnit == NULL) return;

	// Disconnect converter from EQ
	OSErr status = AUGraphDisconnectNodeInput(audioProcessingGraph, eqNode, 0);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't disconnect EQ input");
        return;
    }
	
	// Disconnect EQ from output
	status = AUGraphDisconnectNodeInput(audioProcessingGraph, outputNode, 0);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't disconnect output input");
        return;
    }
	
	status = AUGraphRemoveNode(audioProcessingGraph, eqNode);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't remove EQ node");
        return;
    }
	
	AudioUnitUninitialize(eqUnit);
	eqUnit = NULL;
	eqNode = 0;
	
	// Connect converter to output
	status = AUGraphConnectNodeInput(audioProcessingGraph, inputConverterNode, 0, outputNode, 0);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't connect converter to output");
        return;
    }
	
	status = AUGraphUpdate(audioProcessingGraph, NULL);
	if (status != noErr) {
        NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Couldn't update graph");
        return;
    }
}

#pragma mark -
#pragma mark Queue Control

-(void)startAudioQueue {
    if (audioProcessingGraph == NULL)
        return;
    
    AUGraphStart(audioProcessingGraph);
	if (outputUnit != NULL)
		AudioOutputUnitStart(outputUnit);
}

-(void)stopAudioQueue {
    if (audioProcessingGraph == NULL)
        return;
    
	// Sometimes, because Core Audio is such a young, untested API, AUGraphStop… doesn't.
	// There's probably some dumb thing I'm doing wrong here.
	Boolean isRunning = NO;
	AUGraphIsRunning(audioProcessingGraph, &isRunning);
	
	for (NSUInteger i = 0; i < 10 && isRunning; i++) {
		AUGraphStop(audioProcessingGraph);
		AUGraphIsRunning(audioProcessingGraph, &isRunning);
	}
	
	if (isRunning)
		NSLog(@"[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), @"Failed to stop audio graph!");
	
	// Forcefully stop the output audio unit too.
	if (outputUnit != NULL)
		AudioOutputUnitStop(outputUnit);
}

-(void)clearAudioBuffers {
	[self.audioBuffer clear];
}

#pragma mark -
#pragma mark Setup and Teardown

-(void)teardownCoreAudio {
    if (audioProcessingGraph == NULL)
        return;
    
    [self stopAudioQueue];
	
    AUGraphStop(audioProcessingGraph);
	AUGraphUninitialize(audioProcessingGraph);
	DisposeAUGraph(audioProcessingGraph);
	
	audioProcessingGraph = NULL;
	outputUnit = NULL;
	eqUnit = NULL;
	inputConverterUnit = NULL;
}

-(BOOL)setupCoreAudioWithInputFormat:(AudioStreamBasicDescription)inputFormat error:(NSError **)err {
    
    if (audioProcessingGraph != NULL)
        [self teardownCoreAudio];
	
    // A description of the output device we're looking for.
    AudioComponentDescription outputDescription;
    outputDescription.componentType = kAudioUnitType_Output;
    outputDescription.componentSubType = kAudioUnitSubType_DefaultOutput;
    outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    outputDescription.componentFlags = 0;
    outputDescription.componentFlagsMask = 0;
	
	// A description for the libspotify -> standard PCM device
	AudioComponentDescription converterDescription;
	converterDescription.componentType = kAudioUnitType_FormatConverter;
	converterDescription.componentSubType = kAudioUnitSubType_AUConverter;
	converterDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	converterDescription.componentFlags = 0;
	converterDescription.componentFlagsMask = 0;	
    
	// Create an AUGraph
	OSErr status = NewAUGraph(&audioProcessingGraph);
	if (status != noErr) {
        fillWithError(err, @"Couldn't init graph", status);
        return NO;
    }
	
	// Open the graph. AudioUnits are open but not initialized (no resource allocation occurs here)
	AUGraphOpen(audioProcessingGraph);
	if (status != noErr) {
        fillWithError(err, @"Couldn't open graph", status);
        return NO;
    }
	
	// Add audio output...
	status = AUGraphAddNode(audioProcessingGraph, &outputDescription, &outputNode);
	if (status != noErr) {
        fillWithError(err, @"Couldn't add output node", status);
        return NO;
    }
	
	// Get output unit so we can change volume etc
	status = AUGraphNodeInfo(audioProcessingGraph, outputNode, NULL, &outputUnit);
	if (status != noErr) {
        fillWithError(err, @"Couldn't get output unit", status);
        return NO;
    }
	
	// Create PCM converter
	status = AUGraphAddNode(audioProcessingGraph, &converterDescription, &inputConverterNode);
	if (status != noErr) {
        fillWithError(err, @"Couldn't add converter node", status);
        return NO;
    }
	
	status = AUGraphNodeInfo(audioProcessingGraph, inputConverterNode, NULL, &inputConverterUnit);
	if (status != noErr) {
        fillWithError(err, @"Couldn't get input unit", status);
        return NO;
    }
	
	// Set render callback
	AURenderCallbackStruct rcbs;
	rcbs.inputProc = VivaAudioUnitRenderDelegateCallback;
	rcbs.inputProcRefCon = (__bridge void *)(self);
	
	status = AUGraphSetNodeInputCallback(audioProcessingGraph, inputConverterNode, 0, &rcbs);
	if (status != noErr) {
        fillWithError(err, @"Couldn't add render callback", status);
        return NO;
    }
	
	// Connect converter to output
	status = AUGraphConnectNodeInput(audioProcessingGraph, inputConverterNode, 0, outputNode, 0);
	if (status != noErr) {
        fillWithError(err, @"Couldn't connect converter to output", status);
        return NO;
    }
	
	// Init Queue
	status = AUGraphInitialize(audioProcessingGraph);
	if (status != noErr) {
		fillWithError(err, @"Couldn't initialize graph", status);
        return NO;
	}
	
	AUGraphUpdate(audioProcessingGraph, NULL);
	
	// Apply properties and let's get going!
    [self startAudioQueue];
	[self applyAudioStreamDescriptionToInputUnit:inputFormat];
    [self applyVolumeToOutputAudioUnit:self.volume];
	
	if (self.eqEnabled)
		[self enableEQAudioUnit];
	
    return YES;
}

static void fillWithError(NSError **mayBeAnError, NSString *localizedDescription, int code) {
    if (mayBeAnError == NULL)
        return;
    
    *mayBeAnError = [NSError errorWithDomain:@"com.vivaplaybackmanager.coreaudio"
                                        code:code
                                    userInfo:localizedDescription ? [NSDictionary dictionaryWithObject:localizedDescription
                                                                                                forKey:NSLocalizedDescriptionKey]
                                            : nil];
    
}

static UInt32 framesSinceLastTimeUpdate = 0;
static UInt32 framesSinceLastFFTUpdate = 0;

static OSStatus VivaAudioUnitRenderDelegateCallback(void *inRefCon,
                                                    AudioUnitRenderActionFlags *ioActionFlags,
                                                    const AudioTimeStamp *inTimeStamp,
                                                    UInt32 inBusNumber,
                                                    UInt32 inNumberFrames,
                                                    AudioBufferList *ioData) {
	
    SPCoreAudioController *self = (__bridge SPCoreAudioController *)inRefCon;
	
	AudioBuffer *buffer = &(ioData->mBuffers[0]);
	UInt32 bytesRequired = buffer->mDataByteSize;
	
	NSUInteger availableData = [self.audioBuffer length];
	if (availableData < bytesRequired) {
		buffer->mDataByteSize = 0;
		*ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
		return noErr;
    }
    
    buffer->mDataByteSize = (UInt32)[self.audioBuffer readDataOfLength:bytesRequired intoAllocatedBuffer:&buffer->mData];
    
	framesSinceLastTimeUpdate += inNumberFrames;
    framesSinceLastFFTUpdate += inNumberFrames;
	
	if (framesSinceLastTimeUpdate >= 8820) {
        // Update 5 times per second
		
		[self->incrementTrackPositionInvocation setArgument:&framesSinceLastTimeUpdate atIndex:2];
		[self->incrementTrackPositionInvocation performSelectorOnMainThread:@selector(invoke)
                                                                 withObject:nil
                                                              waitUntilDone:NO];
		framesSinceLastTimeUpdate = 0;
	}
    
    if (framesSinceLastFFTUpdate >= 2205) {
        short *frames = buffer->mData;
        performAcceleratedFastFourierTransformWithWaveform(self, frames, inNumberFrames, self->leftChannelMagnitudes, self->rightChannelMagnitudes);
        
        [self performSelectorOnMainThread:@selector(updateLevels)
                               withObject:nil
                            waitUntilDone:NO];
        
		framesSinceLastFFTUpdate = 0;
    }
    
    return noErr;
}

-(void)incrementTrackPositionWithFrameCount:(UInt32)framesToAppend {
	[self.delegate coreAudioController:self didOutputAudioOfDuration:framesToAppend/self.inputAudioDescription.mSampleRate];
}

-(void)updateLevels {
    
	NSMutableArray *leftArray = [[NSMutableArray alloc] initWithCapacity:exp2(fftMagnitudeExponent)];
	NSMutableArray *rightArray = [[NSMutableArray alloc] initWithCapacity:exp2(fftMagnitudeExponent)];
	
	for (int currentLevel = 0; currentLevel < exp2(fftMagnitudeExponent); currentLevel++) {
        
        double left = leftChannelMagnitudes[currentLevel] / 10.0;
        double right = rightChannelMagnitudes[currentLevel] / 10.0;
        left = cbrt(MIN(1.0, MAX(0.0, left)));
        right = cbrt(MIN(1.0, MAX(0.0, right)));
        
        [leftArray addObject:[NSNumber numberWithDouble:left]];
        [rightArray addObject:[NSNumber numberWithDouble:right]];
    }
	
	self.leftLevels = leftArray;
    self.rightLevels = rightArray;
}

#pragma mark -
#pragma mark Fourier Transforms

static double *leftInputRealBuffer = NULL;
static double *leftInputImagBuffer = NULL;
static double *rightInputRealBuffer = NULL;
static double *rightInputImagBuffer = NULL;

static vDSP_Length fftSetupForSampleCount = 0;

static void performAcceleratedFastFourierTransformWithWaveform(SPCoreAudioController *manager, short *frames, vDSP_Length frameCount, double *leftDestination, double *rightDestination) {
	if (leftDestination == NULL || rightDestination == NULL || frames == NULL || frameCount == 0)
		return;
	
    FFTSetupD fft_weights = manager->fft_weights;
    
    if (frameCount != fftSetupForSampleCount) {
        /* Allocate memory to store split-complex input and output data */
        
        if (leftInputRealBuffer != NULL) free(leftInputRealBuffer);
        if (leftInputImagBuffer != NULL) free(leftInputImagBuffer);
        
        leftInputRealBuffer = (double *)malloc(frameCount * sizeof(double));
        leftInputImagBuffer = (double *)malloc(frameCount * sizeof(double));
        
        if (rightInputRealBuffer != NULL) free(rightInputRealBuffer);
        if (rightInputImagBuffer != NULL) free(rightInputImagBuffer);
        
        rightInputRealBuffer = (double *)malloc(frameCount * sizeof(double));
        rightInputImagBuffer = (double *)malloc(frameCount * sizeof(double));
        
        fftSetupForSampleCount = frameCount;
    }
    
    memset(leftInputRealBuffer, 0, frameCount * sizeof(double));
    memset(rightInputRealBuffer, 0, frameCount * sizeof(double));
    memset(leftInputImagBuffer, 0, frameCount * sizeof(double));
    memset(rightInputImagBuffer, 0, frameCount * sizeof(double));
    
    DSPDoubleSplitComplex leftInput = {leftInputRealBuffer, leftInputImagBuffer};
    DSPDoubleSplitComplex rightInput = {rightInputRealBuffer, rightInputImagBuffer};
    
    // Left
    for (int i = 0; i < frameCount; i++) {
        leftInput.realp[i] = ((double)frames[i * 2]) / INT16_MAX;
        rightInput.realp[i] = ((double)frames[(i * 2) + 1]) / INT16_MAX;
    }
    
    /* 1D in-place complex FFT */
    vDSP_fft_zipD(fft_weights, &leftInput, 1, fftMagnitudeExponent, FFT_FORWARD);
    // Get magnitudes
    vDSP_zvmagsD(&leftInput, 1, leftDestination, 1, exp2(fftMagnitudeExponent));
    
    /* 1D in-place complex FFT */
    vDSP_fft_zipD(fft_weights, &rightInput, 1, fftMagnitudeExponent, FFT_FORWARD);
    // Get magnitudes
    vDSP_zvmagsD(&rightInput, 1, rightDestination, 1, exp2(fftMagnitudeExponent));   
}


@end
