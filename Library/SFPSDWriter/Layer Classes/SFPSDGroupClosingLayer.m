//
//  SFPSDGroupClosingLayer.m
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//
//  Inspired by PSDWriter by Ben Gotow ( https://github.com/bengotow/PSDWriter )
//

#import "SFPSDGroupClosingLayer.h"

#import "NSMutableData+SFAppendValue.h"

@implementation SFPSDGroupClosingLayer

@synthesize groupOpeningLayer = _groupOpeningLayer;

#pragma mark - Overrides of SFPSDLayer functions

- (NSData *)extraLayerInformation
{
    NSMutableData *extraDataStream = [[NSMutableData alloc] init];
    
    if (nil != [self groupOpeningLayer]) {
        [self copyGroupInformationFrom:[self groupOpeningLayer]];
    }
    
    [extraDataStream sfAppendValue:0 length:4]; // Layer mask / adjustment layer data. Size of the data: 36, 20, or 0.
    [extraDataStream sfAppendValue:0 length:4]; // Layer blending ranges data. Length of layer blending ranges data
    
    // Layer name: Pascal string, padded to a multiple of 4 bytes.
    [self writeNameOn:extraDataStream withPadding:4];
    
    // Section divider setting (Photoshop 6.0)
    [extraDataStream sfAppendUTF8String:@"8BIM" length:4];
    [extraDataStream sfAppendUTF8String:@"lsct" length:4];
    [extraDataStream sfAppendValue:12 length:4]; // Section divider length
    
    if (self.isOpened) {
        [extraDataStream sfAppendValue:1 length:4]; // Type. 0 = any other type of layer, 1 = open "folder", 2 = closed "folder", 3 = bounding section divider, hidden in the UI
    }
    else {
        [extraDataStream sfAppendValue:2 length:4]; // Type. 0 = any other type of layer, 1 = open "folder", 2 = closed "folder", 3 = bounding section divider, hidden in the UI
    }
    
    [extraDataStream sfAppendUTF8String:@"8BIM" length:4];
    [extraDataStream sfAppendUTF8String:SFPSDLayerBlendModePassThrough length:4]; // Blend mode: pass

    // Writing the Effects Layer containing information about Drop Shadow, Inner Shadow, Outer Glow, Inner Glow, Bevel, Solid Fill
    [self writeEffectsLayerOn:extraDataStream];

    // Unicode layer name (Photoshop 5.0). Unicode string (4 bytes length + string).
    [self writeUnicodeNameOn:extraDataStream];
    
    return extraDataStream;
}

@end
