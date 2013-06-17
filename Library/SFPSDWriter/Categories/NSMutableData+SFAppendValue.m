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

@end
