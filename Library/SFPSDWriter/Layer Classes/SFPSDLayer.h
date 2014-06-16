//
//  SFPSDLayer.h
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//
//  Inspired by PSDWriter by Ben Gotow ( https://github.com/bengotow/PSDWriter )
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "SFPSDLayerBlendModes.h"
#import "SFPSDEffectsLayerEffectSignatures.h"

#import "SFPSDEffectLayerInformations.h"

@interface SFPSDLayer : NSObject
{
}

/** The size of the document the layer will be insert into. */
@property (nonatomic, assign) CGSize documentSize;

/** The name of the layer. */
@property (nonatomic, strong) NSString *name;

/** The image reference */
@property (nonatomic, assign) CGImageRef image;

/** 
 * The image data in RGBA format.
 *
 * The data is kept as property because of the massive use in the PSD generation phase. The 
 * data is created on first usage and niled every time the image changes. */
@property (nonatomic, strong) NSData *visibleImageData;

//@property (nonatomic, assign) CGRect imageRegion;

/** The opacity of the layer between 0 and 1. */
@property (nonatomic, assign) float opacity;

/** Layer offset */
@property (nonatomic, assign) CGPoint offset;

/** Number of channels of the layer. Defaults to 4. */
@property (nonatomic, assign) NSInteger numberOfChannels;

/** 
 * Allows you to automatically vertically flip the image data when it's being
 * written to PSD. This is important if the source images are coming from OpenGL or
 * another drawing system with an inverted coordinate system. */
@property (nonatomic, assign) BOOL shouldFlipLayerData;

/** 
 * Allows you to automatically unpremultiply the image data. Premultiplication is
 * a process by which the R,G, and B values are multiplied by the alpha. Setting this
 * to YES will cause RGB to be divided by A. You'll know you need to do this if the
 * image comes out darker than you expect. */
@property (nonatomic, assign) BOOL shouldUnpremultiplyLayerData;

/** Layer blend mode. */
@property (nonatomic, strong) NSString *blendMode;

#pragma mark - Effects Layer Informations

/** Effects Layer information for the Drop Shafow Effect 
  * Can be found in the "Layer -> Layer Style" menu in Photoshop */
@property (nonatomic, strong) SFPSDDropShadowEffectLayerInformation *dropShadowEffectLayerInformation;

/** Effects Layer information for the Inner Shafow Effect
 * Can be found in the "Layer -> Layer Style" menu in Photoshop */
@property (nonatomic, assign) SFPSDInnerShadowEffectLayerInformation *innerShadowEffectLayerInformation;

/** Effects Layer information for the Outer Glow Effect
 * Can be found in the "Layer -> Layer Style" menu in Photoshop */
@property (nonatomic, assign) SFPSDOuterGlowEffectLayerInformation *outerGlowEffectLayerInformation;

/** Effects Layer information for the Inner Glow Effect
 * Can be found in the "Layer -> Layer Style" menu in Photoshop */
@property (nonatomic, assign) SFPSDInnerGlowEffectLayerInformation *innerGlowEffectLayerInformation;

/** Effects Layer information for the Bevel Effect
 * Can be found in the "Layer -> Layer Style" menu in Photoshop */
@property (nonatomic, assign) SFPSDBevelEffectLayerInformation *bevelEffectLayerInformation;

/** Effects Layer information for the Solid Fill Effect
 * Can be found in the "Layer -> Layer Style" menu in Photoshop */
@property (nonatomic, assign) SFPSDSolidFillEffectLayerInformation *solidFillEffectLayerInformation;

#pragma mark - Initializers

/** Designed initializer. */
- (id)initWithNumberOfChannels:(int)numberOfChannels andOpacity:(float)opacity andShouldFlipLayerData:(BOOL)shouldFlipLayerData andShouldUnpremultiplyLayerData:(BOOL)shouldUnpremultiplyLayerData andBlendMode:(NSString *)blendMode;

/** 
 * Returns a Boolean value that indicates whether the layer has some printable content inside the document bounds.
 * @return YES if the layer can be printed inside the document bounds. NO if the layer is entirely outside the document bounds. */
- (BOOL)hasValidSize;

/**  The part of the image to use in the layer depending on position. If some part of the layer is out of bounds the image is cropped. */
- (CGRect)imageCropRegion;

/** The portion of the document occupied by the image. */
- (CGRect)imageInDocumentRegion;

/**
 * The CGImage cropped usign the CGRect provided by -imageCropRegion. */
- (CGImageRef)croppedImage;

/**
 * Writes the Layer Information Section inside the mutable data (the first part of the "Layer info"
 * section of the "Layer and mask information section")
 *
 * Adobe documentation: Information about each layer. See Layer records describes the structure of
 * this information for each layer. */
- (void)writeLayerInformationOn:(NSMutableData *)layerInformation;

/** 
 * Writes the "Channel Image Data" inside the mutable data (the second part of the "Layer info"
 * section of the "Layer and mask information section")
 *
 * Adobe documentation: Channel image data. Contains one or more image data records (see See Channel
 * image data for structure) for each layer. The layers are in the same order as in the layer
 * information (previous row of this table). */
- (void)writeLayerChannelsOn:(NSMutableData *)layerInformation;

@end

@interface SFPSDLayer (Protected)

/** Returns an array of the channels composing the layer. */
- (NSArray *)layerChannels;

/** Writes the name on data. Tipically used in the "extra data field". */
- (void)writeNameOn:(NSMutableData *)data withPadding:(int)padding;

/** Writes the Effects Layer containing information about Drop Shadow, Inner Shadow, 
  * Outer Glow, Inner Glow, Bevel, Solid Fill. Tipically used in the "extra data field". */
- (void)writeEffectsLayerOn:(NSMutableData *)data;

/** Writes the unicode name on data. Tipically used in the "extra data field". */
- (void)writeUnicodeNameOn:(NSMutableData *)data;

/** Extra layer information data. Has to be overridden in the extended classes (i.e. in the
 * PSDGroupOpeningLayer and PSDGroupClosingLayer). */
- (NSData *)extraLayerInformation;

@end

/** 
 * A convenience function for getting RGBA NSData from a CGImageRef.
 */
NSData *CGImageGetData(CGImageRef image, CGRect region);