//
//  SFPSDGroupLayer.h
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SFPSDLayer.h"

@interface SFPSDGroupLayer : SFPSDLayer

/** If the group layer is shown opened or closed. Default is NO */
@property (nonatomic, assign) BOOL isOpened;

/** Simple initializer. */
- (id)initWithName:(NSString *)name;

/** Designed initializer. */
- (id)initWithName:(NSString *)name andOpacity:(float)opacity andIsOpened:(BOOL)isOpened;

/** 
 * Copies the Group layer information from another Group layer
 * Useful if you want to setup the information on the Closing Group Layer and don't remember
 * the information you've put in the Opening one */
- (void)copyGroupInformationFrom:(SFPSDGroupLayer *)layer;

@end
