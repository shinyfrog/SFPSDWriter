//
//  SFPSDWriter.m
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//
//  Inspired by PSDWriter by Ben Gotow ( https://github.com/bengotow/PSDWriter )
//

#import "SFPSDWriter.h"

#import "NSMutableData+SFAppendValue.h"
#import "NSData+SFPackedBits.h"

@interface SFPSDWriter()

// Private methods declaration
- (void)resetFlattenedContext;
- (BOOL)addLayerToFlattenedContext:(SFPSDLayer *)layer error:(NSError * __autoreleasing *)error;
- (void)writeFileHeaderSectionOn:(NSMutableData *)result;
- (void)writeColorModeDataSectionOn:(NSMutableData *)result;
- (void)writeImageResourceSectionOn:(NSMutableData *)result;
- (void)writeLayerAndMaskInformationSectionOn:(NSMutableData *)result;
- (void)writeImageDataSectionOn:(NSMutableData *)result;

@end

@implementation SFPSDWriter

@synthesize documentSize = _documentSize, documentResolution = _documentResolution, documentResolutionUnit = _documentResolutionUnit, layers = _layers, hasTransparentLayers = _hasTransparentLayers, flattenedData = _flattenedData, flattenedContext = _flattenedContext, colorProfile = _colorProfile;

#pragma mark - Init and dealloc

- (id)init
{
    return [self initWithDocumentSize:CGSizeMake(0, 0)
                        andResolution:72.0
                    andResolutionUnit:SFPSDResolutionUnitPPI
              andHasTransparentLayers:YES
                            andLayers:nil];
}

- (id)initWithDocumentSize:(CGSize)documentSize
{
    return [self initWithDocumentSize:documentSize
                        andResolution:72.0
                    andResolutionUnit:SFPSDResolutionUnitPPI
              andHasTransparentLayers:YES
                            andLayers:nil];
}

- (id)initWithDocumentSize:(CGSize)documentSize
             andResolution:(float)resolution
         andResolutionUnit:(SFPSDResolutionUnit)resolutionUnit
{
        return [self initWithDocumentSize:documentSize
                            andResolution:resolution
                        andResolutionUnit:resolutionUnit
                  andHasTransparentLayers:YES
                                andLayers:nil];
}

// Kept for backward compatibility - it is suggested to use the designed initializer with the resolution value
// This initializer will be dismissed
- (id)initWithDocumentSize:(CGSize)documentSize
   andHasTransparentLayers:(BOOL)hasTransparentLayers
                 andLayers:(NSArray *)layers
{
    return [self initWithDocumentSize:documentSize
                        andResolution:72.0
                    andResolutionUnit:SFPSDResolutionUnitPPI
              andHasTransparentLayers:hasTransparentLayers
                            andLayers:layers];
}

- (id)initWithDocumentSize:(CGSize)documentSize
             andResolution:(float)resolution
         andResolutionUnit:(SFPSDResolutionUnit)resolutionUnit
   andHasTransparentLayers:(BOOL)hasTransparentLayers
                 andLayers:(NSArray *)layers
{
    self = [super init];
    if (!self) return nil;
    

    self.flattenedContext = nil;
    self.flattenedData = nil;

    [self setHasTransparentLayers:hasTransparentLayers];    
    [self setDocumentSize:documentSize];

    // By default there is no embedded color profile
    [self setColorProfile:SFPSDNoColorProfile];
    
    if (resolutionUnit == SFPSDResolutionUnitPPC) {
        // Converting the resolution to PPC
        resolution = resolution * 2.54;
    }
    
    SFPSDResolution currentDocumentResolution;
    currentDocumentResolution.hResolution = resolution;
    currentDocumentResolution.vResolution = resolution;
    [self setDocumentResolution:currentDocumentResolution];
    
    [self setDocumentResolutionUnit:resolutionUnit];
    
    if (nil != layers) {
        self.layers = [[NSMutableArray alloc] initWithArray:layers];
    }
    else {
        self.layers = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
	[self setLayers:nil];
	[self setFlattenedData:nil];

    // If the flatten context is set it surely must be released
    if (_flattenedContext != nil) {
        CGContextRelease(_flattenedContext);
        _flattenedContext = nil;
    }
}

#pragma mark - Setters

- (void)setDocumentSize:(CGSize)documentSize
{
    if (_documentSize.width == documentSize.width && _documentSize.height == documentSize.height) {
        return;
    }
    
    _documentSize = documentSize;
    
    // Changing the document size of each layer
    for (int i = 0; i < [[self layers] count]; i++) {
        [[[self layers] objectAtIndex:i] setDocumentSize:documentSize];
    }
    
    [self resetFlattenedContext];
}

#pragma mark - Getters

- (int)numberOfChannels
{
    if ([self hasTransparentLayers]) {
        return 4;
    }
    
    return 3;
}

- (NSArray *)visibleLayers
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject hasValidSize];
    }];
    return [[self layers] filteredArrayUsingPredicate:predicate];
}

#pragma mark - Layer creation

- (SFPSDLayer *)addLayerWithCGImage:(CGImageRef)image andName:(NSString*)name
{
    return [self addLayerWithCGImage:image andName:name andOpacity:1.0 andOffset:CGPointMake(0, 0)];
}

- (SFPSDLayer *)addLayerWithCGImage:(CGImageRef)image andName:(NSString*)name andOpacity:(float)opacity andOffset:(CGPoint)offset
{
    SFPSDLayer * layer = [[SFPSDLayer alloc] init];
    
    [layer setDocumentSize:self.documentSize];
    
    [layer setImage:image];
    [layer setOpacity: opacity];
    [layer setName: name];
    [layer setOffset:offset];
    [layer setNumberOfChannels:[self numberOfChannels]];
    
    [[self layers] addObject:layer];
    
    NSError *error = nil;
    [self addLayerToFlattenedContext:layer error:&error];
    
    return layer;
}

- (SFPSDGroupOpeningLayer *)openGroupLayerWithName:(NSString *)name
{
    return [self openGroupLayerWithName:name andOpacity:1.0 andIsOpened:NO];
}

- (SFPSDGroupOpeningLayer *)openGroupLayerWithName:(NSString *)name andOpacity:(float)opacity andIsOpened:(BOOL)isOpened
{
    SFPSDGroupOpeningLayer *layer = [[SFPSDGroupOpeningLayer alloc] initWithName:name andOpacity:opacity andIsOpened:isOpened];
    layer.documentSize = self.documentSize;
    [self.layers addObject: layer];
    return layer;
}

- (SFPSDGroupClosingLayer *)closeCurrentGroupLayer
{
    NSError *error = nil;
    return [self closeCurrentGroupLayerWithError:&error];
}

- (SFPSDGroupClosingLayer *)closeCurrentGroupLayerWithError:(NSError * __autoreleasing *)error
{
    // Retrieving the last opened (and not closed) group
    SFPSDGroupOpeningLayer *lastOpenedGroup = nil;
    int closedGroups = 0;
    for (SFPSDLayer *layer in [self.layers reverseObjectEnumerator]) {
        if ([layer isKindOfClass:[SFPSDGroupClosingLayer class]]) {
            ++closedGroups;
        }
        if ([layer isKindOfClass:[SFPSDGroupOpeningLayer class]]) {
            if (closedGroups == 0) {
                lastOpenedGroup = (SFPSDGroupOpeningLayer *)layer;
                break;
            }
            else {
                --closedGroups;
            }
        }
    }
    
    if (nil == lastOpenedGroup) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"There is no opened layer to close" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"net.shinyfrog.SFPSDWriter" code:3 userInfo:errorDetail];
        return nil;
    }
    
    SFPSDGroupClosingLayer *layer = [[SFPSDGroupClosingLayer alloc] init];
    [layer setDocumentSize:self.documentSize];
    [layer setGroupOpeningLayer:lastOpenedGroup];
    
    [[self layers] addObject:layer];
    
    return layer;
}

#pragma mark - Flattened content handling

- (void)resetFlattenedContext
{
    // If flattened context already exists it will be recreated
    if (_flattenedContext != nil) {
        CGContextRelease(_flattenedContext);
        _flattenedContext = nil;
    }
    
    if ([self documentSize].height <= 0 && [self documentSize].width <= 0) {
        return;
    }
    
    // Recreating the context
    CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
    _flattenedContext = CGBitmapContextCreate(NULL, _documentSize.width, _documentSize.height, 8, 0, colorSpaceRGB, kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpaceRGB);
    
    float backgroundAlpha = 1;
    if  ([self hasTransparentLayers]) {
        backgroundAlpha = 0;
    }
    
    CGContextSetRGBFillColor(_flattenedContext, 1, 1, 1, backgroundAlpha);
    CGContextFillRect(_flattenedContext, CGRectMake(0, 0, [self documentSize].width, [self documentSize].height));
    
    // Adding the image of each existing layer
    if ([[self visibleLayers] count]) {
        for (int i = 0; i < [[self visibleLayers] count]; i++) {
            [[self.layers objectAtIndex:i] setDocumentSize:[self documentSize]];
            
            NSError *error = nil;
            [self addLayerToFlattenedContext:[[self visibleLayers] objectAtIndex:i] error:&error];
        }
    }
}

- (BOOL)addLayerToFlattenedContext:(SFPSDLayer *)layer error:(NSError * __autoreleasing *)error
{
    if ((self.documentSize.width <= 0) || (self.documentSize.height <= 0)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"You must specify a non-zero documentSize before adding a layer" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"net.shinyfrog.SFPSDWriter" code:1 userInfo:errorDetail];
        return  NO;
    }

    CGRect drawRegion = [layer imageInDocumentRegion];
    drawRegion.origin.y = self.documentSize.height - (drawRegion.origin.y + drawRegion.size.height);

    CGContextSetAlpha(self.flattenedContext, [layer opacity]);
    CGContextDrawImage(self.flattenedContext, drawRegion, [layer croppedImage]);
    CGContextSetAlpha(self.flattenedContext, [layer opacity]);
    
    return YES;
}

#pragma mark - Layer preprocessing

- (void)preprocess
{	
    // do we have a flattenedContext that needs to become flattenedData?
    if (self.flattenedContext != nil) {
        CGImageRef i = CGBitmapContextCreateImage(self.flattenedContext);
        self.flattenedData = CGImageGetData(i, CGRectMake(0, 0, self.documentSize.width, self.documentSize.height));
        CGImageRelease(i);
    }
    
    for (SFPSDLayer *layer in self.layers) {
        
        if (![layer shouldFlipLayerData] && ![layer shouldUnpremultiplyLayerData]) {
            continue;
        }
        
        NSData *d = [layer visibleImageData];
        
		UInt8 *data = (UInt8 *)[d bytes];
		unsigned long length = [d length];
		
        // perform unpremultiplication
		if (layer.shouldUnpremultiplyLayerData) {
			for(long i = 0; i < length; i += 4) {
				float a = ((float)data[(i + 3)]) / 255.0;
				data[(i + 0)] = (int) fmax(0, fmin((float)data[(i + 0)] / a, 255));
				data[(i + 1)] = (int) fmax(0, fmin((float)data[(i + 1)] / a, 255));
				data[(i + 2)] = (int) fmax(0, fmin((float)data[(i + 2)] / a, 255));
			}
		}

        // perform flip over vertical axis
		if (layer.shouldFlipLayerData) {
			for (int x = 0; x < self.documentSize.width; x++) {
				for (int y = 0; y < self.documentSize.height/2; y++) {
					int top_index = (x + y * self.documentSize.width) * 4;
					int bottom_index = (x + (self.documentSize.height - y - 1)*self.documentSize.width) * 4;
					char saved;
					
					for (int a = 0; a < 4; a++) {
						saved = data[top_index + a];
						data[top_index + a] = data[bottom_index + a];
						data[bottom_index + a] = saved;
					}
				}
			}
		}
	}
    
    // Closing all the eventual groups opened and not closed
    int groupsToClose = 0;
    for (SFPSDLayer *layer in [self layers]) {
        if ([layer isKindOfClass:[SFPSDGroupOpeningLayer class]]) {
            ++groupsToClose;
        }
        else if ([layer isKindOfClass:[SFPSDGroupClosingLayer class]]) {
            --groupsToClose;
        }
    }
    for (int i = 0; i < groupsToClose; i++) {
        [self closeCurrentGroupLayer];
    }
}

#pragma mark - PSD Crating functions

- (NSData *)createPSDData
{
    NSError *error = nil;
    return [self createPSDDataWithError:&error];
}

- (NSData *)createPSDDataWithError:(NSError * __autoreleasing *)error
{
	NSMutableData *result = [NSMutableData data];
    
    if ([[self visibleLayers] count] == 0) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"No visible layers in the document" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"net.shinyfrog.SFPSDWriter" code:2 userInfo:errorDetail];
        return  result;
    }
	
	// Modify the input data if necessary
	[self preprocess];
	
    // Write the File Header Section
	[self writeFileHeaderSectionOn:result];
    
    // Write the Color Mode Data Section
	[self writeColorModeDataSectionOn:result];
	
    // Write the Image Resources Section
    [self writeImageResourceSectionOn:result];
	
    // Write the Layer and Mask Information Section
    [self writeLayerAndMaskInformationSectionOn:result];
	
    // Write the Image Data Section
	[self writeImageDataSectionOn:result];
	
	return result;
}

// FILE HEADER SECTION
// -----------------------------------------------------------------------------------------------
- (void)writeFileHeaderSectionOn:(NSMutableData *)result
{
	// write the signature
	[result sfAppendUTF8String:@"8BPS" length:4];
	
	// write the version number
	[result sfAppendValue:1 length:2];
	
	// write reserved blank space
	[result sfAppendValue:0 length:6];
	
	// write number of channels
    [result sfAppendValue:[self numberOfChannels] length:2];
	
	// write height then width of the image in pixels
	[result sfAppendValue:self.documentSize.height length:4];
	[result sfAppendValue:self.documentSize.width length:4];
	
	// write number of bits per channel
	[result sfAppendValue:8 length:2];
	
	// write color mode (3 = RGB)
	[result sfAppendValue:3 length:2];
}

// COLOR MODE DATA SECTION
// -----------------------------------------------------------------------------------------------
- (void)writeColorModeDataSectionOn:(NSMutableData *)result
{
	// write color mode data section
	[result sfAppendValue:0 length:4];
}

// IMAGE RESOURCES SECTION
// -----------------------------------------------------------------------------------------------
- (void)writeImageResourceSectionOn:(NSMutableData *)result
{
	// write images resources section. This is used to store things like current layer.
	NSMutableData *imageResources = [NSMutableData data];
	
	// write the resolutionInfo structure. Don't have the definition for this, so we
	// have to just paste in the right bytes.
	[imageResources sfAppendUTF8String:@"8BIM" length:4];
	[imageResources sfAppendValue:1005 length:2]; // 1005 - ResolutionInfo structure - See Appendix A in Photoshop API Guide.pdf
	[imageResources sfAppendValue:0 length:2];
	[imageResources sfAppendValue:16 length:4];
    
    // Converting the resolution to a fixed point 16-binary digit number
    UInt32 hResolution = self.documentResolution.hResolution * 65536.0 + 0.5;
    UInt32 vResolution = self.documentResolution.vResolution * 65536.0 + 0.5;
    
    // write the current resolution info
    [imageResources sfAppendValue:hResolution length:4];                    // hRes - Horizontal resolution in pixels per inch
    [imageResources sfAppendValue:self.documentResolutionUnit length:2];    // hResUnit - 1 = display horitzontal resolution in pixels per inch; 2 = display horitzontal resolution in pixels per cm
    [imageResources sfAppendValue:1 length:2];                              // widthUnit - Display width as 1=inches; 2=cm; 3=points; 4=picas; 5=columns
    [imageResources sfAppendValue:vResolution length:4];                    // vRes -  Vertial resolution in pixels per inch
    [imageResources sfAppendValue:self.documentResolutionUnit length:2];    // vResUnit - 1 = display horitzontal resolution in pixels per inch; 2 = display horitzontal resolution in pixels per cm
    [imageResources sfAppendValue:1 length:2];                              // heightUnit - Display width as 1=inches; 2=cm; 3=points; 4=picas; 5=columns
	
	// write the current layer structure
	[imageResources sfAppendUTF8String:@"8BIM" length:4];
	[imageResources sfAppendValue:1024 length:2]; // 1024 - Layer state information - 2 bytes containing the index of target layer (0 = bottom layer)
	[imageResources sfAppendValue:0 length:2];
	[imageResources sfAppendValue:2 length:4];
	[imageResources sfAppendValue:0 length:2]; // current layer = 0

    // Embedded Color Profile data
    if ([self colorProfile] != SFPSDNoColorProfile) {

        // We have to use the NSData of the [NSColorSpace ICCProfileData] saved to the files
        // because iOS does not have NSColorProfile
        NSString *ICCProfileDataFilePath;

        switch ([self colorProfile]) {
            case SFPSDAdobeRGB1998ColorProfile:
                ICCProfileDataFilePath = [[NSBundle mainBundle] pathForResource:@"AdobeRGB1998" ofType:@""];
                break;
            case SFPSDGenericRGBColorProfile:
                ICCProfileDataFilePath = [[NSBundle mainBundle] pathForResource:@"GenericRGB" ofType:@""];
                break;
            case SFPSDSRGBColorProfile:
                ICCProfileDataFilePath = [[NSBundle mainBundle] pathForResource:@"sRGB" ofType:@""];
                break;
            default:
                /* this is an unreachable case */
                break;
        }

        NSData *ICCProfileData = [NSData dataWithContentsOfFile:ICCProfileDataFilePath];

        [imageResources sfAppendUTF8String:@"8BIM" length:4];
        [imageResources sfAppendValue:1039 length:2]; // 1039 - The raw bytes of an ICC (International Color Consortium) format profile. See ICC34.pdf in the Documentation folder and ICC34.h in Sample Code\Common\Includes
        [imageResources sfAppendValue:0 length:2];
        [imageResources sfAppendValue:[ICCProfileData length] length:4];
        [imageResources appendData:ICCProfileData];
    }
	
	[result sfAppendValue:[imageResources length] length:4];
	[result appendData:imageResources];
}

// LAYER AND MASK INFORMATION SECTION
// -----------------------------------------------------------------------------------------------
- (void)writeLayerAndMaskInformationSectionOn:(NSMutableData *)result
{
	// layer and mask information section. contains basic data about each layer (its mask, its channels,
	// its layer effects, its annotations, transparency layers, wtf tons of shit.) We need to actually
	// create this.
	
	NSMutableData *layerInfo = [NSMutableData data];
	NSUInteger layerCount = [[self visibleLayers] count];
	
	// write the layer count
	[layerInfo sfAppendValue:layerCount length:2];
    
    // Writing the layer information for each layer
    for (int i = 0; i < [self.layers count]; i++) {
        SFPSDLayer *layer = [self.layers objectAtIndex:i];
        
        if (![layer hasValidSize]) {
            continue;
        }
        
        [layer writeLayerInformationOn:layerInfo];
    }
    
    // Writing the layer channels
    for (int i = 0; i < [self.layers count]; i++) {
        SFPSDLayer *layer = [self.layers objectAtIndex:i];
        
        if (![layer hasValidSize]) {
            continue;
        }
        
        [layer writeLayerChannelsOn:layerInfo];
    }
    
	// round to length divisible by 2.
	if ([layerInfo length] % 2 != 0)
		[layerInfo sfAppendValue:0 length:1];
	
	// write length of layer and mask information section
	[result sfAppendValue:[layerInfo length]+4 length:4];
	
	// write length of layer info
	[result sfAppendValue:[layerInfo length] length:4];
	
	// write out actual layer info
	[result appendData:layerInfo];
}

// IMAGE DATA SECTION
// -----------------------------------------------------------------------------------------------
- (void)writeImageDataSectionOn:(NSMutableData *)result
{
	// write compression format = 1 = RLE
	[result sfAppendValue:1 length:2];
	
	// With RLE compression, the image data starts with the byte counts for all of the scan lines (rows * channels)
	// with each count stored as a 2-byte value. The RLE compressed data follows with each scan line compressed
	// separately. Same as the TIFF standard.
	
	// in 512x512 image w/ no alpha, there are 3072 scan line bytes. At 2 bytes each, that means 1536 byte counts.
	// 1536 = 512 rows * three channels.
	
	NSMutableData *byteCounts = [NSMutableData dataWithCapacity:self.documentSize.height * [self numberOfChannels] * 2];
	NSMutableData *scanlines = [NSMutableData data];
	
	int imageRowBytes = self.documentSize.width * 4;
	
	for (int channel = 0; channel < [self numberOfChannels]; channel++) {
		for (int row = 0; row < self.documentSize.height; row++) {
			NSRange packRange = NSMakeRange(row * imageRowBytes + channel, imageRowBytes);
			NSData * packed = [self.flattenedData sfPackedBitsForRange:packRange skip:4];
			[byteCounts sfAppendValue:[packed length] length:2];
			[scanlines appendData:packed];
		}
	}
	
	// chop off the image data from the original file
	[result appendData:byteCounts];
	[result appendData:scanlines];
}

@end