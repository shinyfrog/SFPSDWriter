//
//  NSString+SFPascalString.h
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//
//  Inspired by PSDWriter by Ben Gotow ( https://github.com/bengotow/PSDWriter )
//

#import <Foundation/Foundation.h>

@interface NSString (SFPascalString)

/** Pascal string padded to multiples of the paddind interval. */
- (const char *)sfPascalStringPaddedTo:(int)paddingInterval withPaddingString:(NSString *)paddingString;

/** Pascal string padded to multiples of the paddind interval using as padding the unicode char 0x00. */
- (const char *)sfPascalStringPaddedTo:(int)paddingInterval;

/** The length of the string padded to the multiples of the padding interval. */
- (int)sfPascalStringLengthPaddedTo:(int)paddingInterval;

@end
