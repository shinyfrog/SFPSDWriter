//
//  SFPSDSolidFillEffectLayerInformation.m
//  SFPSDWriter Mac OS X
//
//  Created by Konstantin Erokhin on 15/06/14.
//  Copyright (c) 2014 Shiny Frog. All rights reserved.
//

#import "SFPSDSolidFillEffectLayerInformation.h"

@implementation SFPSDSolidFillEffectLayerInformation

@synthesize blendMode = _blendMode, color = _color, opacity = _opacity, enabled = _enabled;

- (id)init
{
    self = [super init];
    if (self)
    {
        _blendMode = SFPSDLayerBlendModeNormal;

        CGFloat components[4] = {0.0,0.0,0.0,0.0};
        _color = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
        
        _opacity = 100;
        _enabled = NO;
    }
    return self;
}

- (void)setOpacity:(long)opacity
{
    if (opacity < 0) {
        opacity = 0;
    }
    else if (opacity > 100) {
        opacity = 100;
    }
    _opacity = opacity;
}

- (long)opacity255
{
    return 2.55 * _opacity;
}

@end
