//
//  SFPSDLayer.m
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//
//  Inspired by PSDWriter by Ben Gotow ( https://github.com/bengotow/PSDWriter )
//

#import <malloc/malloc.h>

#import "SFPSDLayer.h"

#import "NSMutableData+SFAppendValue.h"
#import "NSData+SFPackedBits.h"
#import "NSString+SFPascalString.h"

@implementation SFPSDLayer

@synthesize image = _image, name = _name, opacity = _opacity, offset = _offset, documentSize = _documentSize, numberOfChannels = _numberOfChannels, visibleImageData = _visibleImageData, blendMode = _blendMode;
@synthesize shouldFlipLayerData = _shouldFlipLayerData, shouldUnpremultiplyLayerData = _shouldUnpremultiplyLayerData;
@synthesize dropShadowEffectLayerInformation = _dropShadowEffectLayerInformation, innerShadowEffectLayerInformation = _innerShadowEffectLayerInformation, outerGlowEffectLayerInformation = _outerGlowEffectLayerInformation, innerGlowEffectLayerInformation = _innerGlowEffectLayerInformation, bevelEffectLayerInformation = _bevelEffectLayerInformation, solidFillEffectLayerInformation = _solidFillEffectLayerInformation;

#pragma mark - Init and dealloc

- (id)init
{
    return [self initWithNumberOfChannels:4 andOpacity:1.0 andShouldFlipLayerData:NO andShouldUnpremultiplyLayerData:NO andBlendMode:SFPSDLayerBlendModeNormal];
}

- (id)initWithNumberOfChannels:(int)numberOfChannels andOpacity:(float)opacity andShouldFlipLayerData:(BOOL)shouldFlipLayerData andShouldUnpremultiplyLayerData:(BOOL)shouldUnpremultiplyLayerData andBlendMode:(NSString *)blendMode
{
    self = [super init];
    if (!self) return nil;
    
    self.numberOfChannels = numberOfChannels;
    self.opacity = opacity;
    self.shouldFlipLayerData = shouldFlipLayerData;
    self.shouldUnpremultiplyLayerData = shouldUnpremultiplyLayerData;
    self.blendMode = blendMode;
    
    return self;
}

- (void)dealloc
{
    self.blendMode = nil;
    self.visibleImageData = nil;
    self.name = nil;
    
    if (_image != nil) {
        CGImageRelease(_image);
        _image = nil;
    }
}

#pragma mark - Setters

- (void)setImage:(CGImageRef)image
{
    // The image is the same
    if (image == _image) {
        return;
    }
    
    // If the image was previously assigned - it is surely a copy and we have to clean it
    if (_image != nil) {
        CGImageRelease(_image);
        _image = nil;
    }
    
    // Assigning
    CGImageRef imageCopy = nil;
    if (image != nil) {
        imageCopy = CGImageCreateCopy(image);
    }
    _image = imageCopy;
    
    // The previously cached imageData is invalid
    [self setVisibleImageData:nil];
}

- (void)setDocumentSize:(CGSize)documentSize
{
    if (_documentSize.width != documentSize.width && _documentSize.height != documentSize.height) {
        _documentSize = documentSize;
    }
    
    // The previously cached imageData is invalid
    [self setVisibleImageData:nil];
}

#pragma mark - Getters

- (NSData *)visibleImageData
{
    if (_visibleImageData == nil) {
        _visibleImageData = CGImageGetData([self croppedImage], [self imageCropRegion]);
    }
    return _visibleImageData;
}

- (CGImageRef)croppedImage
{
    return CGImageCreateWithImageInRect([self image], [self imageCropRegion]);
}

#pragma mark - Size retrieving functions

- (BOOL)hasValidSize
{
    CGRect imageCropRegion = [self imageCropRegion];
    
    // The only test we need to perform to know if the image is inside the document's bounds
    if (imageCropRegion.size.width <= 0 || imageCropRegion.size.height <= 0) {
        return NO;
    }
    
    return YES;
}

- (CGRect)imageCropRegion
{
    CGRect imageCropRegion = CGRectMake(0, 0, CGImageGetWidth(self.image), CGImageGetHeight(self.image));
    
    CGRect imageInDocumentRegion = CGRectMake(self.offset.x, self.offset.y, imageCropRegion.size.width, imageCropRegion.size.height);

    if (imageInDocumentRegion.origin.x < 0) {
        imageCropRegion.size.width = imageCropRegion.size.width + imageInDocumentRegion.origin.x;
        imageCropRegion.origin.x = abs(imageInDocumentRegion.origin.x);
    }
    if (imageInDocumentRegion.origin.y < 0) {
        imageCropRegion.size.height = imageCropRegion.size.height + imageInDocumentRegion.origin.y;
        imageCropRegion.origin.y = abs(imageInDocumentRegion.origin.y);
    }
    
    if (imageInDocumentRegion.origin.x + imageInDocumentRegion.size.width > self.documentSize.width) {
        imageCropRegion.size.width = self.documentSize.width - imageInDocumentRegion.origin.x;
    }
    if (imageInDocumentRegion.origin.y + imageInDocumentRegion.size.height > self.documentSize.height) {
        imageCropRegion.size.height = self.documentSize.height - imageInDocumentRegion.origin.y;
    }

    return  imageCropRegion;
}

- (CGRect)imageInDocumentRegion
{
    CGRect imageCropRegion = [self imageCropRegion];
    CGRect imageInDocumentRegion = CGRectMake(self.offset.x, self.offset.y, imageCropRegion.size.width, imageCropRegion.size.height);
    
    // The layer's image cannot have the origin below the 0...
    imageInDocumentRegion.origin.x = MAX(imageInDocumentRegion.origin.x, 0);
    imageInDocumentRegion.origin.y = MAX(imageInDocumentRegion.origin.y, 0);
    
    // ... and higher of the document bounds
    imageInDocumentRegion.origin.x = MIN(imageInDocumentRegion.origin.x, [self documentSize].width);
    imageInDocumentRegion.origin.y = MIN(imageInDocumentRegion.origin.y, [self documentSize].height);
    
    return imageInDocumentRegion;
}

#pragma mark - Public writing functions

- (void)writeLayerInformationOn:(NSMutableData *)layerInformation
{
    // print out top left bottom right 4x4
    [layerInformation sfAppendValue:0 length:4];
    [layerInformation sfAppendValue:0 length:4];
    [layerInformation sfAppendValue:self.documentSize.height length:4];
    [layerInformation sfAppendValue:self.documentSize.width length:4];
    
    // print out number of channels in the layer
    [layerInformation sfAppendValue:[self numberOfChannels] length:2];
    
    // ARC in this case not cleans the memory used for layerChannels even after the SFPSDWriter is cleared.
    // With an autoreleasepool we force the clean of the memory.
    @autoreleasepool {
        NSArray *layerChannels = [self layerChannels];
        
        // print out data about each channel of the RGB
        for (int i = 0; i < 3; i++) {
            [layerInformation sfAppendValue:i length:2];
            NSUInteger channelInformationLength = [[layerChannels objectAtIndex:i] length];
            [layerInformation sfAppendValue:channelInformationLength length:4];
        }
        
        // If the alpha channel exists
        if ([self numberOfChannels] > 3) {
            // The alpha channel is number -1
            Byte b[2] = {0xFF, 0xFF};
            [layerInformation appendBytes:&b length:2];
            NSUInteger channelInformationLength = [[layerChannels objectAtIndex:3] length];
            [layerInformation sfAppendValue:channelInformationLength length:4];
        }
        
    } // autoreleasepool

    // print out blend mode
    [layerInformation sfAppendUTF8String:@"8BIM" length:4];
    [layerInformation sfAppendUTF8String:[self blendMode] length:4];
    
    // print out opacity
    int opacity = ceilf(self.opacity * 255.0f);
    [layerInformation sfAppendValue:opacity length:1];
    
    // print out clipping
    [layerInformation sfAppendValue:0 length:1]; // 0 = base, 1 = non-base
    
    // print out flags.
    // bit 0 = transparency protected;
    // bit 1 = visible;
    // bit 2 = obsolete;
    // bit 3 = 1 for Photoshop 5.0 and later, tells if bit 4 has useful information;
    // bit 4 = pixel data irrelevant to appearance of document
    [layerInformation sfAppendValue:0 length:1];
    
    // print out filler
    [layerInformation sfAppendValue:0 length:1];
    
    // Overrided in special layers
    NSData *extraData = [self extraLayerInformation];
    
    // print out extra data length
    [layerInformation sfAppendValue:[extraData length] length:4];
    // print out extra data
    [layerInformation appendData:extraData];
}

- (void)writeLayerChannelsOn:(NSMutableData *)layerInformation
{
    // ARC in this case not cleans the memory used for layerChannels even after the SFPSDWriter is cleared.
    // With an autoreleasepool we force the clean of the memory.
    @autoreleasepool {
        NSArray *layerChannels = [self layerChannels];
        for (int i = 0; i < [layerChannels count]; i++) {
            [layerInformation appendData:[layerChannels objectAtIndex:i]];
        }
    } // autoreleasepool
}

#pragma mark - Protecred functions [should never be used from outside the class]

- (NSArray *)layerChannels {
    
    NSMutableArray *channels = [NSMutableArray array];
    
    // This is for later when we write the transparent top and bottom of the shape
	int transparentRowSize = sizeof(Byte) * (int)ceilf(self.documentSize.width * 4);
	Byte *transparentRow = malloc(transparentRowSize);
    
    if ([self numberOfChannels] > 3) {
        memset(transparentRow, 0, transparentRowSize);
    }
    else {
        memset(transparentRow, 255, transparentRowSize); // 255 because we want the not transparent layer be white (0 - will be black)
    }
	
	NSData *transparentRowData = [NSData dataWithBytesNoCopy:transparentRow length:transparentRowSize freeWhenDone:NO];
	NSData *packedTransparentRowData = [transparentRowData sfPackedBitsForRange:NSMakeRange(0, transparentRowSize) skip:4];
    
    CGRect bounds = [self imageInDocumentRegion];
    bounds.origin.x = floorf(bounds.origin.x);
    bounds.origin.y = floorf(bounds.origin.y);
    bounds.size.width = floorf(bounds.size.width);
    bounds.size.height = floorf(bounds.size.height);
    
    int imageRowBytes = bounds.size.width * 4;
    
    NSRange leftPackRange = NSMakeRange(0, (int)bounds.origin.x * 4);
    NSData *packedLeftOfShape = [transparentRowData sfPackedBitsForRange:leftPackRange skip:4];
    NSRange rightPackRange = NSMakeRange(0, (int)(self.documentSize.width - bounds.origin.x - bounds.size.width) * 4);
    NSData *packedRightOfShape = [transparentRowData sfPackedBitsForRange:rightPackRange skip:4];
    
    for (int channel = 0; channel < [self numberOfChannels]; channel++)
    {
        NSMutableData *byteCounts = [[NSMutableData alloc] initWithCapacity:self.documentSize.height * self.numberOfChannels * 2];
        NSMutableData *scanlines = [[NSMutableData alloc] init];
        
        for (int row = 0; row < self.documentSize.height; row++)
        {
            // If it's above or below the shape's bounds, just write black with 0-alpha
            if (row < (int)bounds.origin.y || row >= (int)(bounds.origin.y + bounds.size.height)) {
                [byteCounts sfAppendValue:[packedTransparentRowData length] length:2];
                [scanlines appendData:packedTransparentRowData];
            } else {
                int byteCount = 0;
                
                // Appending the transparent space before the shape
                if (bounds.origin.x > 0.01) {
                    // Append the transparent portion to the left of the shape
                    [scanlines appendData:packedLeftOfShape];
                    byteCount += [packedLeftOfShape length];
                }
                
                // Appending the layer's image row
                NSRange packRange = NSMakeRange((row - (int)bounds.origin.y) * imageRowBytes + channel, imageRowBytes);
                NSData *packed = [[self visibleImageData] sfPackedBitsForRange:packRange skip:4];
                [scanlines appendData:packed];
                byteCount += [packed length];
                
                // Appending the stransparent space after the shape
                if (bounds.origin.x + bounds.size.width < self.documentSize.width) {
                    // Append the transparent portion to the right of the shape
                    [scanlines appendData:packedRightOfShape];
                    byteCount += [packedRightOfShape length];
                }
                
                [byteCounts sfAppendValue:byteCount length:2];
                
                packed = nil;
            }
        }
        
        NSMutableData *channelData = [[NSMutableData alloc] init];
        // write channel compression format
        [channelData sfAppendValue:1 length:2];
        
        // write channel byte counts
        [channelData appendData:byteCounts];
        // write channel scanlines
        [channelData appendData:scanlines];
        
        // add completed channel data to channels array
        [channels addObject:channelData];

        byteCounts = scanlines = nil;
    }
    
    packedLeftOfShape = packedRightOfShape = nil;
    transparentRowData = packedTransparentRowData = nil;
    
    free(transparentRow);
    
    return channels;
}

- (void)writeNameOn:(NSMutableData *)data withPadding:(int)padding
{
    NSString *layerName = [self.name stringByAppendingString:@" "]; // The white space is there to simulate the space reserved by the leading length
    const char *pascalName = [layerName sfPascalStringPaddedTo:4];
    int pascalNameLength = [layerName sfPascalStringLengthPaddedTo:4];
    [data sfAppendValue:[self.name length] length:1];
    [data appendBytes:pascalName length:pascalNameLength - 1]; // -1 because it was the space reserved for writing the heading length of the string
}

#pragma mark EXTRA LAYER INFORMATION

- (void)writeEffectsLayerCommonStateOn:(NSMutableData *)effectsLayerInformation
{
    // DESCRIPTION: Signature
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    // DESCRIPTION: Effects signatures: OSType key for which effects type to use: common state
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:SFPSDEffectsLayerEffectSignatureCommonState length:4];
    // DESCRIPTION: Size of next three items: 7
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:7 length:4];
    // DESCRIPTION: Version: 0
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:0 length:4];
    // DESCRIPTION: Visible: always true
    // LENGTH: 1
    [effectsLayerInformation sfAppendValue:1 length:1];
    // DESCRIPTION: Unused: always 0
    // LENGTH: 2
    [effectsLayerInformation sfAppendValue:0 length:2];
}

- (void)writeEffectsLayerDropShadowOn:(NSMutableData *)effectsLayerInformation
{
    SFPSDDropShadowEffectLayerInformation *currentDropShadow;
    if (nil != [self dropShadowEffectLayerInformation]) {
        currentDropShadow = [self dropShadowEffectLayerInformation];
    }
    else {
        // Default values and not enabled
        currentDropShadow = [[SFPSDDropShadowEffectLayerInformation alloc] init];
    }

    // DESCRIPTION: Signature
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    // DESCRIPTION: Effects signatures: OSType key for which effects type to use: drop shadow
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:SFPSDEffectsLayerEffectSignatureDropShadow length:4];
    // DESCRIPTION: Size of the remaining items: 41 or 51 (depending on version)
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:51 length:4];
    // DESCRIPTION: Version: 0 ( Photoshop 5.0) or 2 ( Photoshop 5.5)
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:2 length:4];
    // DESCRIPTION: Blur value in pixels
    // LENGTH: 4
    // NOTES: I think the real length is 2
    //        "Size" value in Photoshop (0...250) PX
    [effectsLayerInformation sfAppendValue:currentDropShadow.size length:2];
    // DESCRIPTION: Intensity as a percent
    // LENGTH: 4
    // NOTES: Not used in Photoshop
    [effectsLayerInformation sfAppendValue:0 length:4];
    // DESCRIPTION: Angle in degrees
    // LENGTH: 4
    // NOTES: "Angle" in Photoshop (-360...360)
    [effectsLayerInformation sfAppendValue:currentDropShadow.angle length:4];
    // DESCRIPTION: Distance in pixels
    // LENGTH: 4
    // NOTES: "Distance" in Photoshop (0...30000) PX
    [effectsLayerInformation sfAppendValue:currentDropShadow.distance length:4];
    // DESCRIPTION: Not documented
    // LENGTH: -
    // NOTES: I think here are the missing 2 bytes from the blur value
    [effectsLayerInformation sfAppendValue:0 length:2];
    // DESCRIPTION: Color: 2 bytes for space followed by 4 * 2 byte color component
    // LENGTH: 10
    // NOTES: Has no alpha component
    [effectsLayerInformation sfAppendCGColorRef:currentDropShadow.color length:10];
    // DESCRIPTION: Blend mode: 4 bytes for signature and 4 bytes for key
    // LENGTH: 8
    // NOTES: "Blend Mode" in Photoshop
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    [effectsLayerInformation sfAppendUTF8String:currentDropShadow.blendMode length:4];
    // DESCRIPTION: Effect enabled
    // LENGTH: 1
    [effectsLayerInformation sfAppendValue:[[NSNumber numberWithBool:currentDropShadow.enabled] intValue] length:1];
    // DESCRIPTION: Use this angle in all of the layer effects
    // LENGTH: 1
    // NOTES: "Use Global Light" in Photoshop
    [effectsLayerInformation sfAppendValue:[[NSNumber numberWithBool:currentDropShadow.useGlobalLight] integerValue] length:1];
    // DESCRIPTION: Opacity as a percent
    // LENGTH: 1
    // NOTES: (0...255)
    [effectsLayerInformation sfAppendValue:[currentDropShadow opacity255] length:1];
    // DESCRIPTION: (Version 2 only) Native color: 2 bytes for space followed by 4 * 2 byte color component
    // LENGTH: 10
    // NOTES: Has no alpha component
    [effectsLayerInformation sfAppendCGColorRef:currentDropShadow.color length:10];
}

- (void)writeEffectsLayerInnerShadowOn:(NSMutableData *)effectsLayerInformation
{
    SFPSDInnerShadowEffectLayerInformation *currentInnerShadow;
    if (nil != [self innerShadowEffectLayerInformation]) {
        currentInnerShadow = [self innerShadowEffectLayerInformation];
    }
    else {
        // Default values and not enabled
        currentInnerShadow = [[SFPSDInnerShadowEffectLayerInformation alloc] init];
    }

    // DESCRIPTION: Signature
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    // DESCRIPTION: Effects signatures: OSType key for which effects type to use: inner shadow
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:SFPSDEffectsLayerEffectSignatureInnerShadow length:4];
    // DESCRIPTION: Size of the remaining items: 41 or 51 (depending on version)
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:51 length:4];
    // DESCRIPTION: Version: 0 ( Photoshop 5.0) or 2 ( Photoshop 5.5)
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:2 length:4];
    // DESCRIPTION: Blur value in pixels
    // LENGTH: 4
    // NOTES: I think the real length is 2
    //        "Size" value in Photoshop (0...250) PX
    [effectsLayerInformation sfAppendValue:currentInnerShadow.size length:2];
    // DESCRIPTION: Intensity as a percent
    // LENGTH: 4
    // NOTES: Not used in Photoshop
    [effectsLayerInformation sfAppendValue:0 length:4];
    // DESCRIPTION: Angle in degrees
    // LENGTH: 4
    // NOTES: "Angle" in Photoshop (-360...360)
    [effectsLayerInformation sfAppendValue:currentInnerShadow.angle length:4];
    // DESCRIPTION: Distance in pixels
    // LENGTH: 4
    // NOTES: "Distance" in Photoshop (0...30000) PX
    [effectsLayerInformation sfAppendValue:currentInnerShadow.distance length:4];
    // DESCRIPTION: Not documented
    // LENGTH: -
    // NOTES: I think here are the missing 2 bytes from the blur value
    [effectsLayerInformation sfAppendValue:0 length:2];
    // DESCRIPTION: Color: 2 bytes for space followed by 4 * 2 byte color component
    // LENGTH: 10
    // NOTES: Has no alpha component
    [effectsLayerInformation sfAppendCGColorRef:currentInnerShadow.color length:10];
    // DESCRIPTION: Blend mode: 4 bytes for signature and 4 bytes for key
    // LENGTH: 8
    // NOTES: "Blend Mode" in Photoshop
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    [effectsLayerInformation sfAppendUTF8String:SFPSDLayerBlendModeNormal length:4];
    // DESCRIPTION: Effect enabled
    // LENGTH: 1
    [effectsLayerInformation sfAppendValue:[[NSNumber numberWithBool:currentInnerShadow.enabled] intValue] length:1];
    // DESCRIPTION: Use this angle in all of the layer effects
    // LENGTH: 1
    // NOTES: "Use Global Light" in Photoshop
    [effectsLayerInformation sfAppendValue:[[NSNumber numberWithBool:currentInnerShadow.useGlobalLight] integerValue] length:1];
    // DESCRIPTION: Opacity as a percent
    // LENGTH: 1
    // NOTES: (0...255)
    [effectsLayerInformation sfAppendValue:[currentInnerShadow opacity255] length:1];
    // DESCRIPTION: (Version 2 only) Native color: 2 bytes for space followed by 4 * 2 byte color component
    // LENGTH: 10
    // NOTES: Has no alpha component
    [effectsLayerInformation sfAppendCGColorRef:currentInnerShadow.color length:10];
}

- (void)writeEffectsLayerOuterGlowOn:(NSMutableData *)effectsLayerInformation
{
    SFPSDOuterGlowEffectLayerInformation *currentOuterGlow;
    if (nil != [self outerGlowEffectLayerInformation]) {
        currentOuterGlow = [self outerGlowEffectLayerInformation];
    }
    else {
        // Default values and not enabled
        currentOuterGlow = [[SFPSDOuterGlowEffectLayerInformation alloc] init];
    }

    // DESCRIPTION: Signature
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    // DESCRIPTION: Effects signatures: OSType key for which effects type to use: outer glow
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:SFPSDEffectsLayerEffectSignatureOuterGlow length:4];
    // DESCRIPTION: Size of the remaining items: 32 for Photoshop 5.0; 42 for 5.5
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:42 length:4];
    // DESCRIPTION: Version: 0 for Photoshop 5.0; 2 for 5.5
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:2 length:4];
    // DESCRIPTION: Blur value in pixels
    // LENGTH: 4
    // NOTES: I think the real length is 2
    //        "Size" value in Photoshop (0...250) PX
    [effectsLayerInformation sfAppendValue:currentOuterGlow.size length:2];
    // DESCRIPTION: Intensity as a percent
    // LENGTH: 4
    // NOTES: Not used in Photoshop
    [effectsLayerInformation sfAppendValue:0 length:4];
    // DESCRIPTION: Not documented
    // LENGTH: -
    // NOTES: I think here are the missing 2 bytes from the blur value
    [effectsLayerInformation sfAppendValue:0 length:2];
    // DESCRIPTION: Color: 2 bytes for space followed by 4 * 2 byte color component
    // LENGTH: 10
    // NOTES: Has no alpha component
    [effectsLayerInformation sfAppendCGColorRef:currentOuterGlow.color length:10];
    // DESCRIPTION: Blend mode: 4 bytes for signature and 4 bytes for the key
    // LENGTH: 8
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    [effectsLayerInformation sfAppendUTF8String:currentOuterGlow.blendMode length:4];
    // DESCRIPTION: Effect enabled
    // LENGTH: 1
    [effectsLayerInformation sfAppendValue:[[NSNumber numberWithBool:currentOuterGlow.enabled] intValue] length:1];
    // DESCRIPTION: Opacity as a percent
    // LENGTH: 1
    // NOTES: (0...255)
    [effectsLayerInformation sfAppendValue:[currentOuterGlow opacity255] length:1];
    // DESCRIPTION: (Version 2 only) Native color space. 2 bytes for space followed by 4 * 2 byte color component
    // LENGTH: 4
    // NOTES: Has no alpha component
    [effectsLayerInformation sfAppendCGColorRef:currentOuterGlow.color length:10];
}

- (void)writeEffectsLayerInnerGlowOn:(NSMutableData *)effectsLayerInformation
{
    SFPSDInnerGlowEffectLayerInformation *currentInnerGlow;
    if (nil != [self innerGlowEffectLayerInformation]) {
        currentInnerGlow = [self innerGlowEffectLayerInformation];
    }
    else {
        // Default values and not enabled
        currentInnerGlow = [[SFPSDInnerGlowEffectLayerInformation alloc] init];
    }

    // DESCRIPTION: Signature
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    // DESCRIPTION: Effects signatures: OSType key for which effects type to use: inner glow
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:SFPSDEffectsLayerEffectSignatureInnerGlow length:4];
    // DESCRIPTION: Size of the remaining items: 33 for Photoshop 5.0; 43 for 5.5
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:43 length:4];
    // DESCRIPTION: Version: 0 for Photoshop 5.0; 2 for 5.5
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:2 length:4];
    // DESCRIPTION: Blur value in pixels
    // LENGTH: 4
    // NOTES: I think the real length is 2
    //        "Size" value in Photoshop (0...250) PX
    [effectsLayerInformation sfAppendValue:currentInnerGlow.size length:2];
    // DESCRIPTION: Intensity as a percent
    // LENGTH: 4
    // NOTES: Not used in Photoshop
    [effectsLayerInformation sfAppendValue:0 length:4];
    // DESCRIPTION: Not documented
    // LENGTH: -
    // NOTES: I think here are the missing 2 bytes from the blur value
    [effectsLayerInformation sfAppendValue:0 length:2];
    // DESCRIPTION: Color: 2 bytes for space followed by 4 * 2 byte color component
    // LENGTH: 10
    // NOTES: Has no alpha component
    [effectsLayerInformation sfAppendCGColorRef:currentInnerGlow.color length:10];
    // DESCRIPTION: Blend mode: 4 bytes for signature and 4 bytes for the key
    // LENGTH: 8
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    [effectsLayerInformation sfAppendUTF8String:currentInnerGlow.blendMode length:4];
    // DESCRIPTION: Effect enabled
    // LENGTH: 1
    [effectsLayerInformation sfAppendValue:[[NSNumber numberWithBool:currentInnerGlow.enabled] intValue] length:1];
    // DESCRIPTION: Opacity as a percent
    // LENGTH: 1
    // NOTES: (0...255)
    [effectsLayerInformation sfAppendValue:[currentInnerGlow opacity255] length:1];
    // DESCRIPTION: (Version 2 only) Invert
    // LENGTH: 1
    // NOTES: "Source" value in Photoshop -> 0: Center | 1: Edge
    [effectsLayerInformation sfAppendValue:currentInnerGlow.source length:1];
    // DESCRIPTION: (Version 2 only) Native color space. 2 bytes for space followed by 4 * 2 byte color component
    // LENGTH: 10
    // NOTES: Has no alpha component
    [effectsLayerInformation sfAppendCGColorRef:currentInnerGlow.color length:10];
}

- (void)writeEffectsLayerBevelOn:(NSMutableData *)effectsLayerInformation
{
    SFPSDBevelEffectLayerInformation *currentBevel;
    if (nil != [self bevelEffectLayerInformation]) {
        currentBevel = [self bevelEffectLayerInformation];
    }
    else {
        // Default values and not enabled
        currentBevel = [[SFPSDBevelEffectLayerInformation alloc] init];
    }

    // DESCRIPTION: Signature
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    // DESCRIPTION: Effects signatures: OSType key for which effects type to use: bevel
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:SFPSDEffectsLayerEffectSignatureBevel length:4];
    // DESCRIPTION: Size of the remaining items (58 for version 0, 78 for version 20
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:78 length:4];
    // DESCRIPTION: Version: 0 for Photoshop 5.0; 2 for 5.5
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:2 length:4];
    // DESCRIPTION: Angle in degrees
    // LENGTH: 4
    // NOTES: I think the real length is 2
    [effectsLayerInformation sfAppendValue:currentBevel.angle length:2];
    // DESCRIPTION: Strength. Depth in pixels
    // LENGTH: 4
    // NOTES: Not used in Photoshop
    //        (1...250)
    [effectsLayerInformation sfAppendValue:1 length:4];
    // DESCRIPTION: Blur value in pixels.
    // LENGTH: 4
    // NOTES: "Size" value in Photoshop (0...250) PX
    //        The behaviour of this value is very strange. For example with the Emboss style it is doubled inside Photoshop
    //        Furthermore the "Depth" Photoshop value (which we apparently have no access to) seems to be influenced by
    //        this size
    [effectsLayerInformation sfAppendValue:currentBevel.size length:4];
    // DESCRIPTION: Not documented
    // LENGTH: -
    // NOTES: I think here are the missing 2 bytes from the angle value
    [effectsLayerInformation sfAppendValue:0 length:2];
    // DESCRIPTION: Highlight blend mode: 4 bytes for signature and 4 bytes for the key
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    [effectsLayerInformation sfAppendUTF8String:currentBevel.highlightBlendMode length:4];
    // DESCRIPTION: Shadow blend mode: 4 bytes for signature and 4 bytes for the key
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    [effectsLayerInformation sfAppendUTF8String:currentBevel.shadowBlendMode length:4];
    // DESCRIPTION: Highlight color: 2 bytes for space followed by 4 * 2 byte color component
    // LENGTH: 10
    // NOTES: Has no alpha component
    [effectsLayerInformation sfAppendCGColorRef:currentBevel.highlightColor length:10];
    // DESCRIPTION: Shadow color: 2 bytes for space followed by 4 * 2 byte color component
    // LENGTH: 10
    // NOTES: Has no alpha component
    [effectsLayerInformation sfAppendCGColorRef:currentBevel.shadowColor length:10];
    // DESCRIPTION: Bevel style
    // LENGTH: 1
    // NOTES: 1: Outer Bevel | 2: Inner Bevel | 3: Emboss | 4: Pillow Emboss | 5: Stroke Emboss
    [effectsLayerInformation sfAppendValue:currentBevel.style length:1];
    // DESCRIPTION: Hightlight opacity as a percent
    // LENGTH: 1
    // NOTES: (0...255)
    [effectsLayerInformation sfAppendValue:[currentBevel highlightOpacity255] length:1];
    // DESCRIPTION: Shadow opacity as a percent
    // LENGTH: 1
    // NOTES:(0...255)
    [effectsLayerInformation sfAppendValue:[currentBevel shadowOpacity255] length:1];
    // DESCRIPTION: Effect enabled
    // LENGTH: 1
    [effectsLayerInformation sfAppendValue:[[NSNumber numberWithBool:currentBevel.enabled] intValue] length:1];
    // DESCRIPTION: Use this angle in all of the layer
    // LENGTH: 1
    // NOTES: "Use Global Light" in Photoshop
    [effectsLayerInformation sfAppendValue:[[NSNumber numberWithBool:currentBevel.useGlobalLight] intValue] length:1];
    // DESCRIPTION: Up or down
    // LENGTH: 1
    // NOTES: "Direction" value in Photoshop (1: Down, 2: Up)
    [effectsLayerInformation sfAppendValue:currentBevel.direction length:1];
    // DESCRIPTION: Real highlight color: 2 bytes for space; 4 * 2 byte color component
    // LENGTH: 10
    // NOTES: Has no alpha component
    //        Not used in Photoshop
    [effectsLayerInformation sfAppendCGColorRef:currentBevel.highlightColor length:10];
    // DESCRIPTION: Real shadow color: 2 bytes for space; 4 * 2 byte color component
    // LENGTH: 10
    // NOTES: Has no alpha component
    //        Not used in Photoshop
    [effectsLayerInformation sfAppendCGColorRef:currentBevel.shadowColor length:10];
}

- (void)writeEffectsLayerSolidFillOn:(NSMutableData *)effectsLayerInformation
{
    SFPSDSolidFillEffectLayerInformation *currentSolidFill;
    if (nil != [self solidFillEffectLayerInformation]) {
        currentSolidFill = [self solidFillEffectLayerInformation];
    }
    else {
        // Default values and not enabled
        currentSolidFill = [[SFPSDSolidFillEffectLayerInformation alloc] init];
    }

    // DESCRIPTION: Signature
    // LENGTH: 4
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    // DESCRIPTION: Effects signatures: OSType key for which effects type to use: solid fill
    // LENGTH: 4
    // NOTES:
    [effectsLayerInformation sfAppendUTF8String:SFPSDEffectsLayerEffectSignatureSolidFill length:4];
    // DESCRIPTION: Size: 34
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:34 length:4];
    // DESCRIPTION: Version: 2
    // LENGTH: 4
    [effectsLayerInformation sfAppendValue:2 length:4];
    // DESCRIPTION: Key for blend mode
    // LENGTH: 4
    // NOTES: I think it is the blending mode 4 + 4
    [effectsLayerInformation sfAppendUTF8String:@"8BIM" length:4];
    [effectsLayerInformation sfAppendUTF8String:currentSolidFill.blendMode length:4];
    // DESCRIPTION: Color space
    // LENGTH: 10
    // NOTES: Has no alpha component
    //        Seems to be the fill collor
    [effectsLayerInformation sfAppendCGColorRef:currentSolidFill.color length:10];
    // DESCRIPTION: Opacity
    // LENGTH: 1
    // NOTES: (0...255)
    [effectsLayerInformation sfAppendValue:[currentSolidFill opacity255] length:1];
    // DESCRIPTION: Enabled
    // LENGTH: 1
    [effectsLayerInformation sfAppendValue:currentSolidFill.enabled length:1];
    // DESCRIPTION: Native color space
    // LENGTH: 4
    // NOTES:
    [effectsLayerInformation sfAppendCGColorRef:currentSolidFill.color length:10];
}

- (void)writeEffectsLayerOn:(NSMutableData *)data
{

    // We'll include the effects layer informations only if there is at least one effect enabled
    if ((nil == [self dropShadowEffectLayerInformation] || ![self dropShadowEffectLayerInformation].enabled) &&
        (nil == [self innerShadowEffectLayerInformation] || ![self innerShadowEffectLayerInformation].enabled) &&
        (nil == [self outerGlowEffectLayerInformation] || ![self outerGlowEffectLayerInformation].enabled) &&
        (nil == [self innerGlowEffectLayerInformation] || ![self innerGlowEffectLayerInformation].enabled) &&
        (nil == [self bevelEffectLayerInformation] || ![self bevelEffectLayerInformation].enabled) &&
        (nil == [self solidFillEffectLayerInformation] || ![self solidFillEffectLayerInformation].enabled)) {
        return;
    }

    // Temporary data container used to calculate the Effects Layer length before writing it on the data
    NSMutableData *effectsLayerInformation = [NSMutableData data];

    // DESCRIPTION: Version: 0
    // LENGTH: 2
    [effectsLayerInformation sfAppendValue:0 length:2];
    // DESCRIPTION: Effects count: may be 6 (for the 6 effects in Photoshop 5 and 6) or 7 (for Photoshop 7.0)
    // LENGTH: 2
    [effectsLayerInformation sfAppendValue:7 length:2];

    // COMMON STATE
    // ------------------------------------------------------------------------
    [self writeEffectsLayerCommonStateOn:effectsLayerInformation];

    // DROP SWADOW
    // ------------------------------------------------------------------------
    [self writeEffectsLayerDropShadowOn:effectsLayerInformation];

    // INNER SWADOW
    // ------------------------------------------------------------------------
    [self writeEffectsLayerInnerShadowOn:effectsLayerInformation];

    // OUTER GLOW
    // ------------------------------------------------------------------------
    [self writeEffectsLayerOuterGlowOn:effectsLayerInformation];

    // INNER GLOW
    // ------------------------------------------------------------------------
    [self writeEffectsLayerInnerGlowOn:effectsLayerInformation];

    // BEVEL
    // ------------------------------------------------------------------------
    [self writeEffectsLayerBevelOn:effectsLayerInformation];

    // SOLID FILL
    // ------------------------------------------------------------------------
    [self writeEffectsLayerSolidFillOn:effectsLayerInformation];

    // Appending to the data
    // ------------------------------------------------------------------------

    // round to length divisible by 2.
    // Requested by the spect but seems to be useless
	if ([effectsLayerInformation length] % 2 != 0)
		[effectsLayerInformation sfAppendValue:0 length:1];


    // DESCRIPTION: Signature: '8BIM' or '8B64'
    // LENGTH: 4
    [data sfAppendUTF8String:@"8BIM" length:4];
    // DESCRIPTION: Key: a 4-character code (See individual sections)
    // LENGTH: 4
    // NOTES: Effects Layer (Photoshop 5.0)
    //        The key for the effects layer is 'lrFX'.
    [data sfAppendUTF8String:@"lrFX" length:4];
    // DESCRIPTION: Length data below, rounded up to an even byte count.
    // LENGTH: 4
    [data sfAppendValue:[effectsLayerInformation length] length:4];
    // DESCRIPTION: Data
    // LENGTH: Variable
    [data appendData:effectsLayerInformation];
    
}

- (void)writeUnicodeNameOn:(NSMutableData *)data
{
    [data sfAppendUTF8String:@"8BIM" length:4];
    [data sfAppendUTF8String:@"luni" length:4]; // Unicode layer name (Photoshop 5.0)
    
    NSRange r = NSMakeRange(0, [self.name length]);
    
    [data sfAppendValue:(r.length * 2) + 4 length:4]; // length of the next bit of data
    [data sfAppendValue:r.length length:4]; // length of the unicode string data
    
    int bufferSize = sizeof(unichar) * ((int)[self.name length] + 1);
    unichar *buffer = malloc(bufferSize);
    [self.name getCharacters:buffer range:r];
    buffer[([self.name length])] = 0;
    for (NSUInteger i = 0; i < [self.name length]; i++) {
        [data sfAppendValue:buffer[i] length:2];
    }
    free(buffer);
}

- (NSData *)extraLayerInformation
{
    // new stream of data for the extra information
    NSMutableData *extraDataStream = [[NSMutableData alloc] init];

    [extraDataStream sfAppendValue:0 length:4]; // Layer mask / adjustment layer data. Size of the data: 36, 20, or 0.

    [extraDataStream sfAppendValue:0 length:4]; // Layer blending ranges data. Length of layer blending ranges data
    
    // Layer name: Pascal string, padded to a multiple of 4 bytes.
    [self writeNameOn:extraDataStream withPadding:4];

    // Writing the Effects Layer containing information about Drop Shadow, Inner Shadow, Outer Glow, Inner Glow, Bevel, Solid Fill
    [self writeEffectsLayerOn:extraDataStream];

    // Unicode layer name (Photoshop 5.0). Unicode string (4 bytes length + string).
    [self writeUnicodeNameOn:extraDataStream];

    return extraDataStream;
}

#pragma mark - Class description

-(NSString *)description
{
    return [NSString stringWithFormat:@"(super: %@): Layer named '%@' (opacity: %f). Image Crop Region: (%f, %f, %f, %f). Image In Document Region (%f, %f, %f, %f)",
            [super description],
            self.name,
            self.opacity,
            self.imageCropRegion.origin.x,
            self.imageCropRegion.origin.y,
            self.imageCropRegion.size.width,
            self.imageCropRegion.size.height,
            self.imageInDocumentRegion.origin.x,
            self.imageInDocumentRegion.origin.y,
            self.imageInDocumentRegion.size.width,
            self.imageInDocumentRegion.size.height];
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
    CGBitmapInfo bitmapInfo = (CGBitmapInfo)kCGImageAlphaPremultipliedLast; // In order to suppress the warning (http://stackoverflow.com/a/18921840)
	context = CGBitmapContextCreate(bitmapData, width, height, 8, bitmapBytesPerRow,
									colorspace, bitmapInfo);
	//	CGColorSpaceRelease(colorspace);
	
	if (context == NULL)
		// error creating context
		return nil;
	
	// Draw the image to the bitmap context. Once we draw, the memory
	// allocated for the context for rendering will then contain the
	// raw image data in the specified color space.
	CGContextSaveGState(context);
	
	// Draw the image without scaling it to fit the region
	CGRect drawRegion;
	drawRegion.origin = CGPointZero;
	drawRegion.size.width = width;
	drawRegion.size.height = height;
	CGContextTranslateCTM(context,
						  -region.origin.x + (drawRegion.size.width - region.size.width),
						  -region.origin.y - (drawRegion.size.height - region.size.height));
	CGContextDrawImage(context, region, image);
	CGContextRestoreGState(context);
	
	// When finished, release the context
	CGContextRelease(context);
	
	// Now we can get a pointer to the image data associated with the bitmap context.
	
	NSData *data = [NSData dataWithBytes:bitmapData length:bitmapByteCount];
	free(bitmapData);
	
	return data;
}

