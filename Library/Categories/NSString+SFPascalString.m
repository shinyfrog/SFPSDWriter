//
//  NSString+SFPascalString.m
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//
//  Inspired by PSDWriter by Ben Gotow ( https://github.com/bengotow/PSDWriter )
//

#import "NSString+SFPascalString.h"

@implementation NSString (SFPascalString)

- (const char *)sfPascalStringPaddedTo:(int)paddingInterval withPaddingString:(NSString *)paddingString
{
    int paddedStringLength = [self sfPascalStringLengthPaddedTo:paddingInterval];
    NSString *paddedString = [self stringByPaddingToLength:paddedStringLength withString:paddingString startingAtIndex:0];
    return [paddedString UTF8String];
}

- (const char *)sfPascalStringPaddedTo:(int)paddingInterval
{
    const unichar zero = 0x00;
    NSString *paddingString = [NSString stringWithCharacters:(unichar *)&zero length:1];
    return [self sfPascalStringPaddedTo:paddingInterval withPaddingString:paddingString];
}

- (int)sfPascalStringLengthPaddedTo:(int)paddingInterval
{
    int paddingsIntervals = (int)ceilf((float)[self length] / (float)paddingInterval);
    return paddingsIntervals * paddingInterval;
}

@end
