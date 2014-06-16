//
//  SFPSDDropShadowEffectLayerInformation.m
//  SFPSDWriter Mac OS X
//
//  Created by Konstantin Erokhin on 15/06/14.
//  Copyright (c) 2014 Shiny Frog. All rights reserved.
//

#import "SFPSDDropShadowEffectLayerInformation.h"

@implementation SFPSDDropShadowEffectLayerInformation

@synthesize size = _size, angle = _angle, distance = _distance, color = _color, blendMode = _blendMode, enabled = _enabled, useGlobalLight = _useGlobalLight, opacity = _opacity;

- (id)init
{
    self = [super init];
    if (self)
    {
        _size = 0;
        _angle = 0;
        _distance = 0;

        CGFloat components[4] = {0.0,0.0,0.0,0.0};
        _color = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
        
        _blendMode = SFPSDLayerBlendModeNormal;
        _enabled = NO;
        _useGlobalLight = NO;
        _opacity = 100;
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

- (void)setAngle:(long)angle
{
    if (angle < -360) {
        angle = -360;
    }
    else if (angle > 360) {
        angle = 360;
    }
    _angle = angle;
}

- (void)setDistance:(long)distance
{
    if (distance < 0) {
        distance = 0;
    }
    else if (distance > 30000) {
        distance = 30000;
    }
    _distance = distance;
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