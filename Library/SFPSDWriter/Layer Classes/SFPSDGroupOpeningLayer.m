//
//  SFPSDGroupOpeningLayer.m
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//
//  Inspired by PSDWriter by Ben Gotow ( https://github.com/bengotow/PSDWriter )
//

#import "SFPSDGroupOpeningLayer.h"

#import "NSMutableData+SFAppendValue.h"

@implementation SFPSDGroupOpeningLayer

#pragma mark - Overrides of SFPSDLayer functions

- (NSData *)extraLayerInformation
{    
    NSMutableData *extraDataStream = [[NSMutableData alloc] init];
    
    [extraDataStream sfAppendValue:0 length:4]; // Layer mask / adjustment layer data. Size of the data: 36, 20, or 0.
    [extraDataStream sfAppendValue:0 length:4]; // Layer blending ranges data. Length of layer blending ranges data
    
    // Temporally hanging the name to the default PS group's ending marker name
    NSString *layerName = self.name;
    [self setName:@"</Layer group>"];
    
    // Layer name: Pascal string, padded to a multiple of 4 bytes.
    [self writeNameOn:extraDataStream withPadding:4];
    
    // Section divider setting (Photoshop 6.0)
    [extraDataStream sfAppendUTF8String:@"8BIM" length:4];
    [extraDataStream sfAppendUTF8String:@"lsct" length:4];
    [extraDataStream sfAppendValue:4 length:4]; // Section divider length
    [extraDataStream sfAppendValue:3 length:4]; // Type. 0 = any other type of layer, 1 = open "folder", 2 = closed "folder", 3 = bounding section divider, hidden in the UI
    
    // Unicode layer name (Photoshop 5.0). Unicode string (4 bytes length + string).
    [self writeUnicodeNameOn:extraDataStream];
    
    // Restoring the layer name
    [self setName:layerName];
    
    return extraDataStream;
}

@end
