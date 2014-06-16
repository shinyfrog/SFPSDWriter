//
//  SFPSDSolidFillEffectLayerInformation.h
//  SFPSDWriter Mac OS X
//
//  Created by Konstantin Erokhin on 15/06/14.
//  Copyright (c) 2014 Shiny Frog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFPSDLayerBlendModes.h"

@interface SFPSDSolidFillEffectLayerInformation : NSObject

@property (nonatomic, strong) NSString *blendMode;
@property (nonatomic, assign) CGColorRef color;
@property (nonatomic, assign) long opacity; // (0...100)
@property (nonatomic, assign) BOOL enabled;

- (long)opacity255; // (0...255)

@end
