//
//  SFPSDGroupClosingLayer.h
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//
//  Inspired by PSDWriter by Ben Gotow ( https://github.com/bengotow/PSDWriter )
//

#import "SFPSDGroupLayer.h"
#import "SFPSDGroupOpeningLayer.h"

@interface SFPSDGroupClosingLayer : SFPSDGroupLayer

/** 
 * If this property is set - the information from the group opening layer will be copied
 * to the current layer before writing the extra layer information */
@property (nonatomic, strong) SFPSDGroupOpeningLayer *groupOpeningLayer;

@end
