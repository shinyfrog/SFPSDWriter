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

@interface SFPSDWriter : NSObject
{
}

// TODO: THINK ABOUT IT
@property (nonatomic, assign) CGContextRef flattenedContext;

/** 
 * The PSDLayer objects with layer data, names, etc... Note that when you call
 * createPSDData, this array is slowly emptied - the PSDWriter removes the individual layers
 * from memory as it builds the PSD file. */
@property (nonatomic, strong) NSMutableArray *layers;

/** The size of the PSD you're exporting. */
@property (nonatomic, assign) CGSize documentSize;

/** 
 * The number of channels in each layer. Defaults to 4, unless layers
 * are not transparent. At the moment, this setting applies to all layers. */
@property (nonatomic, assign) int layerChannelCount;

/** Optional. The RGBA data for a flattened "preview" of the PSD. */
@property (nonatomic, strong) NSData * flattenedData;

/**
 * Initializes a new PSDWriter for creating a PSD document with the specified size.
 * @param s The document size */
- (id)initWithDocumentSize:(CGSize)s;

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
 * @param image The image to be added. Does not need to be the same size as the document, but it cannot be larger.
 * @param name The name you'd like to give the layer.
 * @param opacity The opacity of the layer, from [0-1]
 * @param offset The offset of the layer within the document. Use this to position layers within the PSD.
 * 
 * The function returns the newly created layer in order to customize it after the creation. */
- (SFPSDLayer *)addLayerWithCGImage:(CGImageRef)image andName:(NSString*)name andOpacity:(float)opacity andOffset:(CGPoint)offset;

/** Opens a new Group layer.
 * The Group will contain all the layers added to the PSDWriter.layers before -closeCurrentGroupLayer is called
 *
 * The function returns the newly created Group layer in order to customize it after the creation. */
- (SFPSDGroupOpeningLayer *)openGroupLayerWithName:(NSString *)name;

/** 
 * Closes the last opened Group layer.
 * The layer will have the name and other data of the OpenGroupLayer that it is closing
 * The function returns the newly created Group layer in order to customize it after the creation. */
- (SFPSDGroupClosingLayer *)closeCurrentGroupLayer;

/**
 * Generates an NSData object representing a PSD image with the width and height specified by documentSize
 * and the contents specified by the layers array. Note that this function can be (and really should be)
 * called on a separate thread.
 *
 * @return PSD data. Write this data to a file or attach it to an email, etc...
 *
 * Note: You cannot call this function multiple times. After calling createPSDData and getting the document data,
 * you should discard the PSDWriter object. This function is destructive and deletes the information you provided
 * in the layers array to conserve memory as it writes the PSD data. */
- (NSData *)createPSDData;

@end

/** A convenience function for getting RGBA NSData from a CGImageRef. */
NSData *CGImageGetData(CGImageRef image, CGRect region);
