//
//  NSMutableData+SFAppendValue.h
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//
//  Inspired by PSDWriter by Ben Gotow ( https://github.com/bengotow/PSDWriter )
//

#import <Foundation/Foundation.h>


@interface NSMutableData (SFAppendValue)

/** 
 * Allows you to append a numeric value to an NSMutableData object and pad it to any length.
 *
 * For example, we could say [data appendValue: 2 withLength: 5], and 00002 would be written
 * into the data object. Very useful for writing to file formats that have header structures
 * that require a certain number of bytes be used for a certain value. i.e. PSD and TIFF
 *
 * @param value: The value to append
 * @param length: The number of bytes that should be used to store the value. The value will be padded
 * to length bytes regardless of the number of bytes required to store it. */
- (void)sfAppendValue:(long)value length:(int)length;

/** Allows you to append a NSString to the NSMutableData object. */
- (void)sfAppendUTF8String:(NSString *)value length:(int)length;

/** Allows you to append a "Native" CGColorRef to the NSMutableData object.
 * For example it is used in the Effects Layer in the Additional Layer Information to write the
 * layer effect color */
- (void)sfAppendCGColorRef:(CGColorRef)color length:(int)length;

@end