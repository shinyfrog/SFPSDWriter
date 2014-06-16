//
//  SFPSDBevelEffectLayerInformation.h
//  SFPSDWriter Mac OS X
//
//  Created by Konstantin Erokhin on 15/06/14.
//  Copyright (c) 2014 Shiny Frog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFPSDLayerBlendModes.h"

typedef enum {
    SFPSDBevelEffectLayerInformationStyleOuterBevel = 1,
    SFPSDBevelEffectLayerInformationStyleInnerBevel = 2,
    SFPSDBevelEffectLayerInformationStyleEmboss = 3,
    SFPSDBevelEffectLayerInformationStylePillowEmboss = 4,
    SFPSDBevelEffectLayerInformationStyleStrokeEmboss = 5
} SFPSDBevelEffectLayerInformationStyle;

typedef enum {
    SFPSDBevelEffectLayerInformationDirectionUp = 0,
    SFPSDBevelEffectLayerInformationDirectionDown = 1

} SFPSDBevelEffectLayerInformationDirection;

@interface SFPSDBevelEffectLayerInformation : NSObject

/** "Angle" Bevel effect configuration inside Photoshop (-360...360) */
@property (nonatomic, assign) long angle;
/** "Size" Bevel effect configuration inside Photoshop (0...250) */
@property (nonatomic, assign) long size;
/** "Highlight Blend Mode" Bevel effect configuration inside Photoshop */
@property (nonatomic, strong) NSString *highlightBlendMode;
/** "Shadow Blend Mode" Bevel effect configuration inside Photoshop */
@property (nonatomic, strong) NSString *shadowBlendMode;
/** Highlight Color Bevel effect configuration inside Photoshop */
@property (nonatomic, assign) CGColorRef highlightColor;
/** Shadow Color Bevel effect configuration inside Photoshop */
@property (nonatomic, assign) CGColorRef shadowColor;
/** "Style" Bevel effect configuration inside Photoshop */
@property (nonatomic, assign) SFPSDBevelEffectLayerInformationStyle style;
/** "Highlight Opacity" Bevel effect configuration inside Photoshop (0...100) */
@property (nonatomic, assign) long highlightOpacity;
/** "Shadow Opacity" Bevel effect configuration inside Photoshop (0...100) */
@property (nonatomic, assign) long shadowOpacity;
/** Set to YES in order to enable the effect */
@property (nonatomic, assign) BOOL enabled;
/** "Use Global Light" Bevel effect configuration inside Photoshop */
@property (nonatomic, assign) BOOL useGlobalLight;
/** "Direction" Bevel effect configuration inside Photoshop */
@property (nonatomic, assign) SFPSDBevelEffectLayerInformationDirection direction;

/** Return a (0...255) value for the highlight opacity */
- (long)highlightOpacity255;
/** Return a (0...255) value for the shadow opacity */
- (long)shadowOpacity255;

@end
