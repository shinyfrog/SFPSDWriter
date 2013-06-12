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

@implementation SFPSDWriter

@synthesize documentSize = _documentSize, layers = _layers, layerChannelCount = _layerChannelCount, flattenedData = _flattenedData, flattenedContext = _flattenedContext;

#pragma mark - Init and dealloc

- (id)init
{
    self = [super init];
    if (self){
        self.layerChannelCount = 4;
        self.flattenedContext = NULL;
        self.flattenedData = nil;
        self.layers = [[NSMutableArray alloc] init];
    }
    return self;    
}

- (id)initWithDocumentSize:(CGSize)s
{
    self = [self init];
    if (self){
        self.documentSize = s;
    }
    return self;
}

- (void)dealloc
{
    if (self.flattenedContext != NULL) {
        CGContextRelease(self.flattenedContext);
        self.flattenedContext = nil;
    }
    
	self.layers = nil;
	self.flattenedData = nil;
}

#pragma mark - Layer creation functions

- (SFPSDLayer *)addLayerWithCGImage:(CGImageRef)image andName:(NSString*)name andOpacity:(float)opacity andOffset:(CGPoint)offset
{
    SFPSDLayer * layer = [[SFPSDLayer alloc] init];
    layer.documentSize = self.documentSize;
    CGRect imageRegion = CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image));
    CGRect screenRegion = CGRectMake(offset.x, offset.y, imageRegion.size.width, imageRegion.size.height);
    CGRect drawRegion = CGRectMake(offset.x, offset.y, imageRegion.size.width, imageRegion.size.height);
    
    if (screenRegion.origin.x + screenRegion.size.width > self.documentSize.width)
        imageRegion.size.width = screenRegion.size.width = self.documentSize.width - screenRegion.origin.x;
    if (screenRegion.origin.y + screenRegion.size.height > self.documentSize.height)
        imageRegion.size.height = screenRegion.size.height = self.documentSize.height - screenRegion.origin.y;
    if (screenRegion.origin.x < 0) {
        imageRegion.origin.x = abs(screenRegion.origin.x);
        screenRegion.origin.x = 0;
        screenRegion.size.width = imageRegion.size.width = imageRegion.size.width - imageRegion.origin.x;
    }
    if (screenRegion.origin.y < 0) {
        imageRegion.origin.y = abs(screenRegion.origin.y);
        screenRegion.origin.y = 0;
        screenRegion.size.height = imageRegion.size.height = imageRegion.size.height - imageRegion.origin.y;
    }
    
    [layer setImageData: CGImageGetData(image, imageRegion)];
    [layer setOpacity: opacity];
    [layer setRect: screenRegion];
    [layer setName: name];
    [self.layers addObject: layer];
    
    if (self.flattenedData == nil) {
        if ((self.documentSize.width == 0) || (self.documentSize.height == 0))
            @throw [NSException exceptionWithName:NSGenericException reason:@"You must specify a non-zero documentSize before calling addLayer:" userInfo:nil];
        
        if (self.flattenedContext == NULL) {
            self.flattenedContext = CGBitmapContextCreate(NULL, self.documentSize.width, self.documentSize.height, 8, 0, CGImageGetColorSpace(image), kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedLast);
            CGContextSetRGBFillColor(self.flattenedContext, 1, 1, 1, 1);
            CGContextFillRect(self.flattenedContext, CGRectMake(0, 0, self.documentSize.width, self.documentSize.height));
        }
        drawRegion.origin.y = self.documentSize.height - (drawRegion.origin.y + drawRegion.size.height);
        CGContextSetAlpha(self.flattenedContext, opacity);
        CGContextDrawImage(self.flattenedContext, drawRegion, image);
        CGContextSetAlpha(self.flattenedContext, opacity);
    }
    
    return layer;
}

- (SFPSDGroupOpeningLayer *)openGroupLayerWithName:(NSString *)name
{
    SFPSDGroupOpeningLayer *layer = [[SFPSDGroupOpeningLayer alloc] init];
    layer.documentSize = self.documentSize;
    [layer setName: name];
    [self.layers addObject: layer];
    return layer;
}

- (SFPSDGroupClosingLayer *)closeCurrentGroupLayer
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
    
    SFPSDGroupClosingLayer *layer = [[SFPSDGroupClosingLayer alloc] init];
    layer.documentSize = self.documentSize;
    [layer copyGroupInformationFrom:lastOpenedGroup];
    [self.layers addObject: layer];
    
    return layer;
}

#pragma mark - Layer preprocessing functions

- (void)preprocess
{	
    // do we have a flattenedContext that needs to become flattenedData?
    if (self.flattenedData == nil) {
        if (self.flattenedContext) {
            CGImageRef i = CGBitmapContextCreateImage(self.flattenedContext);
            self.flattenedData = CGImageGetData(i, CGRectMake(0, 0, self.documentSize.width, self.documentSize.height));
            CGImageRelease(i);
        }
    }
    if (self.flattenedContext) {
        CGContextRelease(self.flattenedContext);
        self.flattenedContext = nil;

    }
    
    for (SFPSDLayer * layer in self.layers)
	{
        
        if ((layer.shouldFlipLayerData == NO) && (layer.shouldUnpremultiplyLayerData == NO)) {
            return;
        }
        
        NSData *d = [layer imageData];
        
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
}

#pragma mark - PSD Crating functions

- (NSData *)createPSDData
{
	NSMutableData *result = [NSMutableData data];
	
	// make sure the user has provided everything we need
	if ((self.layerChannelCount < 3) || ([self.layers count] == 0)) {
        @throw [NSException exceptionWithName:NSGenericException reason:@"Please provide layer data, flattened data and set layer channel count to at least 3." userInfo:nil];
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
	[result sfAppendValue:self.layerChannelCount length:2];
	
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
	NSMutableData *imageResources = [[NSMutableData alloc] init];
	
	// write the resolutionInfo structure. Don't have the definition for this, so we
	// have to just paste in the right bytes.
	[imageResources sfAppendUTF8String:@"8BIM" length:4];
	[imageResources sfAppendValue:1005 length:2];
	[imageResources sfAppendValue:0 length:2];
	[imageResources sfAppendValue:16 length:4];
	Byte resBytes[16] = {0x00, 0x48, 0x00, 0x00,0x00,0x01,0x00,0x01,0x00,0x48,0x00,0x00,0x00,0x01,0x00,0x01};
	[imageResources appendBytes:&resBytes length:16];
	
	// write the current layer structure
	[imageResources sfAppendUTF8String:@"8BIM" length:4];
	[imageResources sfAppendValue:1024 length:2];
	[imageResources sfAppendValue:0 length:2];
	[imageResources sfAppendValue:2 length:4];
	[imageResources sfAppendValue:0 length:2]; // current layer = 0
	
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
	
	NSMutableData *layerInfo = [[NSMutableData alloc] init];
	NSUInteger layerCount = [self.layers count];
	
	// write the layer count
	[layerInfo sfAppendValue:layerCount length:2];
    
    // Writing the layer information for each layer
    for (int i = 0; i < [self.layers count]; i++) {
        [[self.layers objectAtIndex:i] writeLayerInformationOn:layerInfo];
    }
    
    // Writing the layer channels
    for (int i = 0; i < [self.layers count]; i++) {
        [[self.layers objectAtIndex:i] writeLayerChannelsOn:layerInfo];
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
	
	NSMutableData *byteCounts = [NSMutableData dataWithCapacity:self.documentSize.height * self.layerChannelCount * 2];
	NSMutableData *scanlines = [NSMutableData data];
	
	int imageRowBytes = self.documentSize.width * 4;
	
	for (int channel = 0; channel < self.layerChannelCount; channel++) {
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

#pragma mark - Convenience functions

NSData *CGImageGetData(CGImageRef image, CGRect region)
{
	// Create the bitmap context
	CGContextRef	context = NULL;
	void *			bitmapData;
	int				bitmapByteCount;
	int				bitmapBytesPerRow;
	
	// Get image width, height. We'll use the entire image.
	int width = region.size.width;
	int height = region.size.height;
	
	// Declare the number of bytes per row. Each pixel in the bitmap in this
	// example is represented by 4 bytes; 8 bits each of red, green, blue, and
	// alpha.
	bitmapBytesPerRow = (width * 4);
	bitmapByteCount	= (bitmapBytesPerRow * height);
	
	// Allocate memory for image data. This is the destination in memory
	// where any drawing to the bitmap context will be rendered.
	//	bitmapData = malloc(bitmapByteCount);
	bitmapData = calloc(width * height * 4, sizeof(Byte));
	if (bitmapData == NULL)
	{
		return nil;
	}
	
	// Create the bitmap context. We want pre-multiplied ARGB, 8-bits
	// per component. Regardless of what the source image format is
	// (CMYK, Grayscale, and so on) it will be converted over to the format
	// specified here by CGBitmapContextCreate.
	//	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGColorSpaceRef colorspace = CGImageGetColorSpace(image);
	context = CGBitmapContextCreate(bitmapData, width, height, 8, bitmapBytesPerRow,
									colorspace, kCGImageAlphaPremultipliedLast);
	//	CGColorSpaceRelease(colorspace);
	
	if (context == NULL)
		// error creating context
		return nil;
	
	// Draw the image to the bitmap context. Once we draw, the memory
	// allocated for the context for rendering will then contain the
	// raw image data in the specified color space.
	CGContextSaveGState(context);
	
	//	CGContextTranslateCTM(context, -region.origin.x, -region.origin.y);
	//	CGContextDrawImage(context, region, image);
	
	// Draw the image without scaling it to fit the region
	CGRect drawRegion;
	drawRegion.origin = CGPointZero;
	drawRegion.size.width = CGImageGetWidth(image);
	drawRegion.size.height = CGImageGetHeight(image);
	CGContextTranslateCTM(context,
						  -region.origin.x + (drawRegion.size.width - region.size.width),
						  -region.origin.y - (drawRegion.size.height - region.size.height));
	CGContextDrawImage(context, drawRegion, image);
	CGContextRestoreGState(context);
	
	// When finished, release the context
	CGContextRelease(context);
	
	// Now we can get a pointer to the image data associated with the bitmap context.
	
	NSData *data = [NSData dataWithBytes:bitmapData length:bitmapByteCount];
	free(bitmapData);
	
	return data;
}
