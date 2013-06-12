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

@synthesize imageData = _imageData, name = _name, opacity = _opacity, rect = _rect, documentSize = _documentSize, channelCount = _channelCount;
@synthesize shouldFlipLayerData = _shouldFlipLayerData, shouldUnpremultiplyLayerData = _shouldUnpremultiplyLayerData;

- (id)init
{
    self = [super init];
    if (self){
        self.channelCount = 4;
        self.opacity = 1;
        self.shouldFlipLayerData = NO;
        self.shouldUnpremultiplyLayerData = NO;
        self.blendMode = SFPSDLayerBlendModeNormal;
    }
    return self;
}

- (void)dealloc
{
    self.imageData = nil;
    self.name = nil;
}

- (NSArray *)layerChannels {
    
    NSMutableArray *channels = [NSMutableArray array];
    
    // This is for later when we write the transparent top and bottom of the shape
	int transparentRowSize = sizeof(Byte) * (int)ceilf(self.documentSize.width * 4);
	Byte *transparentRow = malloc(transparentRowSize);
	memset(transparentRow, 0, transparentRowSize);
	
	NSData *transparentRowData = [NSData dataWithBytesNoCopy:transparentRow length:transparentRowSize freeWhenDone:NO];
	NSData *packedTransparentRowData = [transparentRowData sfPackedBitsForRange:NSMakeRange(0, transparentRowSize) skip:4];

    CGRect bounds = self.rect;
    bounds.origin.x = floorf(bounds.origin.x);
    bounds.origin.y = floorf(bounds.origin.y);
    bounds.size.width = floorf(bounds.size.width);
    bounds.size.height = floorf(bounds.size.height);
    
    // Check the bounds
    if (bounds.origin.x < 0 || bounds.origin.y < 0) {
        @throw [NSException exceptionWithName:@"LayerOutOfBounds"
                                       reason:[NSString stringWithFormat:@"Layer %@'s x or y origin is negative, which is unsupported", self]
                                     userInfo:nil];
    }
    if (bounds.origin.x + bounds.size.width > self.documentSize.width ||
        bounds.origin.y + bounds.size.height > self.documentSize.height) {
        @throw [NSException exceptionWithName:@"LayerOutOfBounds"
                                       reason:[NSString stringWithFormat:@"Layer %@'s bottom-right corner is beyond the edge of the canvas, which is unsupported", self]
                                     userInfo:nil];
    }
    
    int imageRowBytes = bounds.size.width * 4;
    
    NSRange leftPackRange = NSMakeRange(0, (int)bounds.origin.x * 4);
    NSData *packedLeftOfShape = [transparentRowData sfPackedBitsForRange:leftPackRange skip:4];
    NSRange rightPackRange = NSMakeRange(0, (int)(self.documentSize.width - bounds.origin.x - bounds.size.width) * 4);
    NSData *packedRightOfShape = [transparentRowData sfPackedBitsForRange:rightPackRange skip:4];

    for (int channel = 0; channel < self.channelCount; channel++)
    {
        // TODO: There is a bug (bad access) - we have to solve it. To make it happen
        //       more frequentely - remove the autoreleasepool
        @autoreleasepool {
        
            NSMutableData *byteCounts = [[NSMutableData alloc] initWithCapacity:self.documentSize.height * self.channelCount * 2];
            NSMutableData *scanlines = [[NSMutableData alloc] init];

        
            for (int row = 0; row < self.documentSize.height; row++)
            {
                // If it's above or below the shape's bounds, just write black with 0-alpha
                if (row < (int)bounds.origin.y || row >= (int)(bounds.origin.y + bounds.size.height)) {
                    [byteCounts sfAppendValue:[packedTransparentRowData length] length:2];
                    [scanlines appendData:packedTransparentRowData];
                } else {
                    int byteCount = 0;
                    
                    if (bounds.origin.x > 0.01) {
                        // Append the transparent portion to the left of the shape
                        [scanlines appendData:packedLeftOfShape];
                        byteCount += [packedLeftOfShape length];
                    }
                    
                    NSRange packRange = NSMakeRange((row - (int)bounds.origin.y) * imageRowBytes + channel, imageRowBytes);
                    NSData *packed = [self.imageData sfPackedBitsForRange:packRange skip:4];
                    [scanlines appendData:packed];
                    byteCount += [packed length];
                    
                    if (bounds.origin.x + bounds.size.width < self.documentSize.width) {
                        // Append the transparent portion to the right of the shape
                        [scanlines appendData:packedRightOfShape];
                        byteCount += [packedRightOfShape length];
                    }
                    
                    [byteCounts sfAppendValue:byteCount length:2];
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
        }
    }

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

- (void)writeUnicodeNameOn:(NSMutableData *)data
{
    [data sfAppendUTF8String:@"8BIM" length:4];
    [data sfAppendUTF8String:@"luni" length:4]; // Unicode layer name (Photoshop 5.0)
    
    NSRange r = NSMakeRange(0, [self.name length]);
    
    [data sfAppendValue:(r.length * 2) + 4 length:4]; // length of the next bit of data
    [data sfAppendValue:r.length length:4]; // length of the unicode string data
    
    unichar *buffer = malloc(sizeof(unichar) * ([self.name length] + 1));
    [self.name getCharacters:buffer range:r];
    buffer[([self.name length] + 1)] = 0;
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
    
    // Unicode layer name (Photoshop 5.0). Unicode string (4 bytes length + string).
    [self writeUnicodeNameOn:extraDataStream];
    
    return extraDataStream;
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
    [layerInformation sfAppendValue:self.channelCount length:2];
    
    NSArray *layerChannels = [self layerChannels];
    
    // print out data about each channel
    for (int c = 0; c < 3; c++) {
        [layerInformation sfAppendValue:c length:2];
        [layerInformation sfAppendValue:[[layerChannels objectAtIndex:c] length] length:4];
    }
    
    // The alpha channel is number -1
    Byte b[2] = {0xFF, 0xFF};
    [layerInformation appendBytes:&b length:2];
    [layerInformation sfAppendValue:[[layerChannels objectAtIndex:3] length] length:4];
    
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
    NSArray *layerChannels = [self layerChannels];
    for (int i = 0; i < [layerChannels count]; i++) {
        [layerInformation appendData:[layerChannels objectAtIndex:i]];
    }
}

@end
