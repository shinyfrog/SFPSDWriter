//
//  SFPSDInnerGlowEffectLayerInformation.m
//  SFPSDWriter Mac OS X
//
//  Created by Konstantin Erokhin on 15/06/14.
//  Copyright (c) 2014 Shiny Frog. All rights reserved.
//

#import "SFPSDInnerGlowEffectLayerInformation.h"

@implementation SFPSDInnerGlowEffectLayerInformation

@synthesize size = _size, color = _color, blendMode = _blendMode, enabled = _enabled, opacity = _opacity, source = _source;

- (id)init
{
    self = [super init];
    if (self)
    {
        _size = 0;

        CGFloat components[4] = {0.0,0.0,0.0,0.0};
        _color = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
        
        _blendMode = SFPSDLayerBlendModeNormal;
        _enabled = NO;
        _opacity = 100;
        _source = SFPSDInnerGlowEffectLayerInformationSourceCenter;
    }
    return self;
}

- (void)setSize:(long)size
{
    if (size < 0) {
        size = 0;
    }
    else if (size > 250) {
        size = 250;
    }
    _size = size;
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
