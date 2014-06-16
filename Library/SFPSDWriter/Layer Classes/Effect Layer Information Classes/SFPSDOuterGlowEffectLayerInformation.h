//
//  SFPSDOuterGlowEffectLayerInformation.h
//  SFPSDWriter Mac OS X
//
//  Created by Konstantin Erokhin on 15/06/14.
//  Copyright (c) 2014 Shiny Frog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFPSDLayerBlendModes.h"

@interface SFPSDOuterGlowEffectLayerInformation : NSObject

/** "Size" Outer Glow effect configuration inside Photoshop (0...250) */
@property (nonatomic, assign) long size;
/** Color Outer Glow effect configuration inside Photoshop */
@property (nonatomic, assign) CGColorRef color;
/** "Blend Mode" Outer Glow effect configuration inside Photoshop */
@property (nonatomic, strong) NSString *blendMode;
/** Set to YES in order to enable the effect */
@property (nonatomic, assign) BOOL enabled;
/** "Opacity" Outer Glow effect configuration inside Photoshop (0...100) */
@property (nonatomic, assign) long opacity;

/** Return a (0...255) value for the opacity */
- (long)opacity255;

@end
