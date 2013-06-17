//
//  NSData+SFPackedData.h
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//
//  Inspired by PSDWriter by Ben Gotow ( https://github.com/bengotow/PSDWriter )
//

#import <Foundation/Foundation.h>

@interface NSData (SFPackedBits)

/**
 * Takes packedBits data and prints out a description of the packed contents by
 * running the decode operation and explaining via NSLog how the data is being
 * decoded. Useful for checking that packedBits data is correct. */
- (NSString *)sfPackedBitsDescription;

/**
 * A special version of packedBits which will take the data and pack every nth
 * value.
 *
 * This is important for PSDWriter because it's necessary to encode R, then G,
 * then B, then A data - so we essentially start at offset 0, skip 4, then do offset 1,
 * skip 4, etc... to compress the data with very minimal memory footprint.
 *
 * For normal packbits just to skip = 1
 *
 * @param range: The range within the data object that should be encoded. Useful
 * for specifying a non-zero starting offset to get a certain channel encoded.
 * @param skip: The number of bytes to advance as the data is encoded. Skip = 1 will
 * encode every byte, skip = 4 will encode every fourth byte, and so on. */
- (NSData *)sfPackedBitsForRange:(NSRange)range skip:(int)skip;

@end
