//
//  SFPSDGroupLayer.m
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//

#import "SFPSDGroupLayer.h"

#import "NSMutableData+SFAppendValue.h"

@implementation SFPSDGroupLayer

@synthesize isOpened = _isOpened;

- (id)initWithName:(NSString *)name
{
    return [self initWithName:name andOpacity:1.0 andIsOpened:NO];
}

- (id)initWithName:(NSString *)name andOpacity:(float)opacity andIsOpened:(BOOL)isOpened
{
    self = [super init];
    if (!self) return nil;
    
    self.name = name;
    self.isOpened = isOpened;
    self.opacity = opacity;
    
    return self;
}

- (void)copyGroupInformationFrom:(SFPSDGroupLayer *)layer
{
    // Copying later informations
    [self setName:layer.name];
    [self setOpacity:layer.opacity];
    [self setIsOpened:layer.isOpened];

    // Copying Effect Layers
    [self setDropShadowEffectLayerInformation:layer.dropShadowEffectLayerInformation];
    [self setInnerShadowEffectLayerInformation:layer.innerShadowEffectLayerInformation];
    [self setOuterGlowEffectLayerInformation:layer.outerGlowEffectLayerInformation];
    [self setInnerGlowEffectLayerInformation:layer.innerGlowEffectLayerInformation];
    [self setBevelEffectLayerInformation:layer.bevelEffectLayerInformation];
    [self setSolidFillEffectLayerInformation:layer.solidFillEffectLayerInformation];
}

#pragma mark - Overrides of SFPSDLayer functions

- (NSArray *)layerChannels
{
    // Creating empty channels for the Group Layer with only compression formats
    NSMutableArray *layerChannels = [NSMutableArray array];
    for (int channel = 0; channel < [self numberOfChannels]; channel++) {
        NSMutableData *channelData = [NSMutableData data];
        // write channel compression format
        [channelData sfAppendValue:0 length:2];
        // add completed channel data to channels array
        [layerChannels addObject:channelData];
    }
    return layerChannels;
}

- (BOOL)hasValidSize
{
    // The group layers has always valid size
    return YES;
}

@end