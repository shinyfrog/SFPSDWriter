//
//  SFPSDInnerGlowEffectLayerInformation.h
//  SFPSDWriter Mac OS X
//
//  Created by Konstantin Erokhin on 15/06/14.
//  Copyright (c) 2014 Shiny Frog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFPSDLayerBlendModes.h"

typedef enum {
    SFPSDInnerGlowEffectLayerInformationSourceCenter = 0,
    SFPSDInnerGlowEffectLayerInformationSourceEdge = 1
} SFPSDInnerGlowEffectLayerInformationSource;

@interface SFPSDInnerGlowEffectLayerInformation : NSObject

/** "Size" Inner Glow effect configuration inside Photoshop (0...250) */
@property (nonatomic, assign) long size;
/** Color Inner Glow effect configuration inside Photoshop */
@property (nonatomic, assign) CGColorRef color;
/** "Blend Mode" Inner Glow effect configuration inside Photoshop */
@property (nonatomic, strong) NSString *blendMode;
/** Set to YES in order to enable the effect */
@property (nonatomic, assign) BOOL enabled;
/** "Opacity" Inner Glow effect configuration inside Photoshop (0...100) */
@property (nonatomic, assign) long opacity;
/** "Source" Inner Glow effect configuration inside Photoshop */
@property (nonatomic, assign) SFPSDInnerGlowEffectLayerInformationSource source;

/** Return a (0...255) value for the opacity */
- (long)opacity255;

@end
