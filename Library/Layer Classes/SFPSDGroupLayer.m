//
//  SFPSDGroupLayer.m
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//

#import "SFPSDGroupLayer.h"

@implementation SFPSDGroupLayer

@synthesize isOpened = _isOpened;

- (void)copyGroupInformationFrom:(SFPSDGroupLayer *)layer
{
    [self setName: layer.name];
    [self setOpacity: layer.opacity];
    [self setIsOpened:layer.isOpened];
}

@end
