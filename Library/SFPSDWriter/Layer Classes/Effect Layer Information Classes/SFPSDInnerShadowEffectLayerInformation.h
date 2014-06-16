//
//  SFPSDInnerShadowEffectLayerInformation.h
//  SFPSDWriter Mac OS X
//
//  Created by Konstantin Erokhin on 15/06/14.
//  Copyright (c) 2014 Shiny Frog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFPSDLayerBlendModes.h"

@interface SFPSDInnerShadowEffectLayerInformation : NSObject

/** "Size" Inner Shadow effect configuration inside Photoshop (0...250) */
@property (nonatomic, assign) long size;
/** "Angle" Inner Shadow effect configuration inside Photoshop (-360...360) */
@property (nonatomic, assign) long angle;
/** "Distance" Inner Shadow effect configuration inside Photoshop (0...30000) */
@property (nonatomic, assign) long distance;
/** Color Inner Shadow effect configuration inside Photoshop */
@property (nonatomic, assign) CGColorRef color;
/** "Belnd Mode" Inner Shadow effect configuration inside Photoshop */
@property (nonatomic, strong) NSString *blendMode;
/** Set to YES in order to enable the effect */
@property (nonatomic, assign) BOOL enabled;
/** "Use Global Light" Inner Shadow effect configuration inside Photoshop */
@property (nonatomic, assign) BOOL useGlobalLight;
/** "Opacity" Inner Shadow effect configuration inside Photoshop (0...100) */
@property (nonatomic, assign) long opacity;

/** Return a (0...255) value for the opacity */
- (long)opacity255;

@end
