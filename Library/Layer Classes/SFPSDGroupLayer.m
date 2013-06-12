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
    return [self initWithName:name andOpacity:1 andIsOpened:NO];
}

- (id)initWithName:(NSString *)name andOpacity:(int)opacity andIsOpened:(BOOL)isOpened
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
    [self setName:layer.name];
    [self setOpacity:layer.opacity];
    [self setIsOpened:layer.isOpened];
}

#pragma mark - Overrides of SFPSDLayer functions

- (NSArray *)layerChannels
{
    // Creating empty channels for the Group Layer with only compression formats
    NSMutableArray *layerChannels = [NSMutableArray array];
    for (int channel = 0; channel < self.channelCount; channel++) {
        NSMutableData *channelData = [[NSMutableData alloc] init];
        // write channel compression format
        [channelData sfAppendValue:0 length:2];
        // add completed channel data to channels array
        [layerChannels addObject:channelData];
    }
    return layerChannels;
}

@end