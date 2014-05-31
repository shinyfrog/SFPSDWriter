//
//  SFPSDWriter.h
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

#import "SFPSDLayer.h"
#import "SFPSDGroupOpeningLayer.h"
#import "SFPSDGroupClosingLayer.h"

struct SFPSDResolution {
    float hResolution;
    float vResolution;
};
typedef struct SFPSDResolution SFPSDResolution;

enum SFPSDResolutionUnit {
    SFPSDResolutionUnitPPI = 1,
    SFPSDResolutionUnitPPC = 2
};
typedef enum SFPSDResolutionUnit SFPSDResolutionUnit;

enum SFPSDColorProfile {
    SFPSDNoColorProfile,            // No color profile (Don't Color Manage This Document)
    SFPSDGenericRGBColorProfile,    // Generic RGB
    SFPSDSRGBColorProfile,          // sRGB IEC61966-2.1
    SFPSDAdobeRGB1998ColorProfile   // Adobe RGB (1998)
};
typedef enum SFPSDColorProfile SFPSDColorProfile;

@interface SFPSDWriter : NSObject
{
}

/**  Context used to hold the flattened image for the PSD preview */
@property (nonatomic, assign) CGContextRef flattenedContext;

/** 
 * The PSDLayer objects with layer data, names, etc... Note that when you call
 * createPSDData, this array is slowly emptied - the PSDWriter removes the individual layers
 * from memory as it builds the PSD file. */
@property (nonatomic, strong) NSMutableArray *layers;

/** The size of the PSD you're exporting. */
@property (nonatomic, assign) CGSize documentSize;

/**
 * The pixel per inch property of the resulting document.
 * It is a SFPSDResolution because the document can have different vertical and horizontal resolutions */
@property (nonatomic, assign) SFPSDResolution documentResolution;

/** The unit of the document resolution. */
@property (nonatomic, assign) SFPSDResolutionUnit documentResolutionUnit;

/** The embedded color profile of the document. */
@property (nonatomic, assign) SFPSDColorProfile colorProfile;

/** 
 * The number of channels in each layer. Defaults to 4, unless layers
 * are not transparent. This is the global  */
@property (nonatomic, assign) BOOL hasTransparentLayers;

/** Optional. The RGBA data for a flattened "preview" of the PSD. */
@property (nonatomic, strong) NSData * flattenedData;

/**
 * Initializes a new PSDWriter for creating a PSD document with the specified size.
 * @param size The document size. */
- (id)initWithDocumentSize:(CGSize)documentSize;

/**
 * Initializes a new PSDWriter for creating a PSD document with the specified size and resolution value.
 * @param documentSize The document size.
 * @param resolution The resolution value of the document. */
- (id)initWithDocumentSize:(CGSize)documentSize andResolution:(float)resolution andResolutionUnit:(SFPSDResolutionUnit)resolutionUnit;

/**
 * Designed initializer.
 * 
 * @param documentSize document size.
 * @param resolution The resolution value of the document.
 * @param resolutionUnit The unit of the document resolution.
 * @param hasTransparentLayers tells if the layer has the alpha channel.
 * @param layers Initial layers. */
- (id)initWithDocumentSize:(CGSize)documentSize andResolution:(float)resolution andResolutionUnit:(SFPSDResolutionUnit)resolutionUnit andHasTransparentLayers:(BOOL)hasTransparentLayers andLayers:(NSArray *)layers;

/**
 * Adds a new layer to the PSD image with a name. The opacity of the layer will be 1 and no offset will be applied.
 *
 * @param image The image to be added. Does not need to be the same size as the document. If the image is larger than the document it will be cropped in the final result.
 * @param name The name you'd like to give the layer.
 *
 * @return The newly created layer in order to customize it after the creation. */
- (SFPSDLayer *)addLayerWithCGImage:(CGImageRef)image andName:(NSString*)name;

/**
 * Adds a new layer to the PSD image with the provided properties.
 *
 * If you are using NSImages and not CGImages, use the following code to convert to CGImageRefs:
 *
 *     NSImage* yourImage;
 *     CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)[yourImage TIFFRepresentation], NULL);
 *     CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, NULL);
 *
 * If you prefer, you can setup PSDLayers by yourself
 * and put them in the PSDWriter.layers array, but this method automatically creates the flattenedData,
 * an image that is a flattened preview of the layered PSD. If you populate the layer objects yourself,
 * you need to provide the flattened image data yourself.
 *
 * Note: Having layers partially off the edge of the canvas is not currently supported.
 *
 * @param image The image to be added. Does not need to be the same size as the document. If the image is larger than the document it will be cropped.
 * @param name The name you'd like to give the layer.
 * @param opacity The opacity of the layer, from [0-1]
 * @param offset The offset of the layer within the document. Use this to position layers within the PSD.
 * 
 * @return The newly created layer in order to customize it after the creation. */
- (SFPSDLayer *)addLayerWithCGImage:(CGImageRef)image andName:(NSString*)name andOpacity:(float)opacity andOffset:(CGPoint)offset;

/**
 * Opens a new PSD group.
 *
 * The group will contain all the layers and groups added to the PSDWriter's instance before the corresponding -closeCurrentGroupLayer is called
 *
 * @param name The name of the group
 *
 * @return The newly created Group in order to customize it after the creation. */
- (SFPSDGroupOpeningLayer *)openGroupLayerWithName:(NSString *)name;

/** 
 * Opens a new PSD group.
 *
 * The group will contain all the layers and groups added to the PSDWriter's instance before the corresponding -closeCurrentGroupLayer is called
 *
 * @param name The name of the group
 * @param opacity The opacity of the group
 * @param isOpened If the group should be opened inside the PSD
 *
 * @return The newly created Group in order to customize it after the creation. */
- (SFPSDGroupOpeningLayer *)openGroupLayerWithName:(NSString *)name andOpacity:(float)opacity andIsOpened:(BOOL)isOpened;

/** Closes the corresponding opened PSD group without returning errors. The function will simply return nil if there is no opened group to close. */
- (SFPSDGroupClosingLayer *)closeCurrentGroupLayer;

/** 
 * Closes the corresponding opened PSD group.
 *
 * The layer will have the name and other data of the SFPSDGroupOpeningLayer that it is closing
 *
 * @return The newly created group layer in order to customize it after the creation. */
- (SFPSDGroupClosingLayer *)closeCurrentGroupLayerWithError:(NSError * __autoreleasing *)error;

/** The number of channels of the PSD document. If it has transparencies - 4, else 3. */
- (int)numberOfChannels;

/** An array with only visible layers inside the document bounds. */
- (NSArray *)visibleLayers;

/** Deprecated function. Use -createPSDDataWithError: instead */
- (NSData *)createPSDData;

/**
 * Generates an NSData object representing a PSD image with the width and height specified by documentSize
 * and the contents specified by the layers array. Note that this function can be (and really should be)
 * called on a separate thread.
 *
 * @return PSD data. This data has to be written on a file. */
- (NSData *)createPSDDataWithError:(NSError * __autoreleasing *)error;

@end
