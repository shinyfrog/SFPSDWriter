//
//  NSMutableData+SFAppendValue.m
//  SFPSDWriter
//
//  Created by Konstantin Erokhin on 06/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//
//  Inspired by PSDWriter by Ben Gotow ( https://github.com/bengotow/PSDWriter )
//

#import "NSMutableData+SFAppendValue.h"

@implementation NSMutableData (SFAppendValue)

- (void)sfAppendValue:(long)value length:(int)length
{
	Byte bytes[8];
	
	double divider = 1;
	for (int i = 0; i < length; i++){
		bytes[length - i - 1] = (long)(value / divider) % 256;
		divider *= 256;
	}
    
	[self appendBytes:&bytes length:length];
}

- (void)sfAppendUTF8String:(NSString *)value length:(int)length
{
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    [self appendData:data];
}

- (void)sfAppendCGColorRef:(CGColorRef)color length:(int)length
{
    const CGFloat *colorComponents = CGColorGetComponents(color);
    size_t numberOfComponents = CGColorGetNumberOfComponents(color);

    NSAssert(numberOfComponents == 4, @"The color components should always be 4 (RGBA color)");

    UInt32 redComponent = colorComponents[0] * 65536.0 - 0.5;
    UInt32 greenComponent = colorComponents[1] * 65536.0 - 0.5;
    UInt32 blueComponent = colorComponents[2] * 65536.0 - 0.5;
    //UInt32 alphaComponent = colorComponents[3] * 65536.0 - 0.5;

    // NSLog(@"RGBA(%d, %d, %d, %d)", redComponent, greenComponent, blueComponent, alphaComponent);

    [self sfAppendValue:0 length:2]; //  2 bytes for space
    [self sfAppendValue:redComponent length:2]; // followed by 4 * 2 byte color component
    [self sfAppendValue:greenComponent length:2];
    [self sfAppendValue:blueComponent length:2];
    [self sfAppendValue:0 length:2];
}

@end
