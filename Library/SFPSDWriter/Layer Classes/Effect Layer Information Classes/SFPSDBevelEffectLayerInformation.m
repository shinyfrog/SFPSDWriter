//
//  SFPSDBevelEffectLayerInformation.m
//  SFPSDWriter Mac OS X
//
//  Created by Konstantin Erokhin on 15/06/14.
//  Copyright (c) 2014 Shiny Frog. All rights reserved.
//

#import "SFPSDBevelEffectLayerInformation.h"

@implementation SFPSDBevelEffectLayerInformation

@synthesize angle = _angle, size = _size, highlightBlendMode = _highlightBlendMode, shadowBlendMode = _shadowBlendMode, highlightColor = _highlightColor, shadowColor = _shadowColor, style = _style, highlightOpacity = _highlightOpacity, shadowOpacity = _shadowOpacity, enabled = _enabled, useGlobalLight = _useGlobalLight, direction = _direction;

- (id)init
{
    self = [super init];
    if (self)
    {
        _angle = 0;
        _size = 0;
        _highlightBlendMode = SFPSDLayerBlendModeNormal;
        _shadowBlendMode = SFPSDLayerBlendModeNormal;

        CGFloat components[4] = {0.0,0.0,0.0,0.0};
        _highlightColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
        _shadowColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);

        _style = SFPSDBevelEffectLayerInformationStyleOuterBevel;
        _highlightOpacity = 100;
        _shadowOpacity = 100;
        _enabled = NO;
        _useGlobalLight = YES;
        _direction = SFPSDBevelEffectLayerInformationDirectionDown;
    }
    return self;
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

- (void)setHighlightOpacity:(long)opacity
{
    if (opacity < 0) {
        opacity = 0;
    }
    else if (opacity > 255) {
        opacity = 255;
    }
    _highlightOpacity = opacity;
}

- (void)setShadowOpacity:(long)opacity
{
    if (opacity < 0) {
        opacity = 0;
    }
    else if (opacity > 255) {
        opacity = 255;
    }
    _shadowOpacity = opacity;
}

- (long)highlightOpacity255
{
    return 2.55 * _highlightOpacity;
}

- (long)shadowOpacity255
{
    return 2.55 * _shadowOpacity;
}

@end