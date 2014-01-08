//
//  SFAppDelegate.m
//  SFPSDWriterStressTest
//
//  Created by Konstantin Erokhin on 13/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//

#include <stdlib.h>

#import "SFAppDelegate.h"

#import "NSData+SFPackedBits.h"

@implementation SFAppDelegate

@synthesize writer = _writer;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.writer = [[SFPSDWriter alloc] initWithDocumentSize:CGSizeMake(1000, 1000) andResolution:300.0 andResolutionUnit:SFPSDResolutionUnitPPI andHasTransparentLayers:YES andLayers:nil];
}

- (void)addLayerWithOffset:(CGPoint)offset andOpacity:(float)opacity
{
    CGImageRef image = [[[[NSImage imageNamed:@"layerImage"] representations] objectAtIndex:0] CGImage];
//    CGImageRef imageCMYK = [[[[NSImage imageNamed:@"layerImageCMYK"] representations] objectAtIndex:0] CGImage];
    
    NSString *name = [NSString stringWithFormat:@"random layer %ld", (unsigned long)([self.writer.layers count] + 1)];
    
    [self.writer addLayerWithCGImage:image andName:name andOpacity:opacity andOffset:offset];
//    [self.writer addLayerWithCGImage:imageCMYK andName:name andOpacity:opacity andOffset:offset];

}

- (IBAction)addLayer:(id)sender {
    int wOffsetR = arc4random() % 740;
    int hOffsetR = arc4random() % 790;
    
    CGPoint offset = CGPointMake(wOffsetR, hOffsetR);
    
    int opacityR = arc4random() % 100;
    
    float opacity = (float)opacityR / 100;
    
    [self addLayerWithOffset:offset andOpacity:opacity];
}

- (IBAction)writePSD:(id)sender {
    // We'll write our test file to the Desktop
    NSString *basePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"];
    NSString *fullFilePath = [basePath stringByAppendingPathComponent:@"SFPSDWriter Test File.psd"];
    
    // Retrieving the PSD data
    NSError *error = nil;
    NSData *psd = [self.writer createPSDDataWithError:&error];
    
    if (nil != error) {
        NSLog(@"ERROR? ERROR: %@", [error description]);
    }
    
    // Writing the data on disk
    [psd writeToFile:fullFilePath atomically:NO];
}

- (IBAction)clearPSDWriter:(id)sender {
    [self setWriter:nil];
    self.writer = [[SFPSDWriter alloc] initWithDocumentSize:CGSizeMake(1000, 1000)];
}

- (IBAction)add10Layers:(id)sender {
    for (int i = 0; i < 10; i++) {
        [self addLayer:nil];
    }
}

- (IBAction)add100Layers:(id)sender {
    for (int i = 0; i < 10; i++) {
        [self add10Layers:nil];
    }
}

- (IBAction)writePSD10Times:(id)sender {
    for (int i = 0; i < 10; i++) {
        [self writePSD:nil];
    }
}

- (IBAction)changeImageSize:(id)sender {
    CGSize currentSize = [self.writer documentSize];
    currentSize.width = currentSize.width - 100;
    currentSize.height = currentSize.height - 100;
    [self.writer setDocumentSize:currentSize];
}

- (IBAction)openGroupLayer:(id)sender {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:10];
    for (int i=0; i < 10; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    [self.writer openGroupLayerWithName:randomString andOpacity:1.0 andIsOpened:YES];
}

- (IBAction)closeGroupLayer:(id)sender {
    NSError *error = nil;
    [self.writer closeCurrentGroupLayerWithError:&error];
    
    if (nil != error) {
        NSLog(@"Error in closing group layer: %@", [error debugDescription]);
    }
}

- (IBAction)addTopEscapingLayer:(id)sender
{
    [self addLayerWithOffset:CGPointMake(1000/2 - 250/2, -100) andOpacity:1.0];
}

- (IBAction)addBottomEscapingLayer:(id)sender
{
    [self addLayerWithOffset:CGPointMake(1000/2 - 250/2, 900) andOpacity:1.0];
}

- (IBAction)addLeftEscapingLayer:(id)sender
{
    [self addLayerWithOffset:CGPointMake(-100, 1000/2 - 200/2) andOpacity:1.0];
}

- (IBAction)addRightEscapingLayer:(id)sender
{
    [self addLayerWithOffset:CGPointMake(900, 1000/2 - 200/2) andOpacity:1.0];
}

- (IBAction)addAllEscapingLayers:(id)sender
{
    [self addTopEscapingLayer:nil];
    [self addBottomEscapingLayer:nil];
    [self addLeftEscapingLayer:nil];
    [self addRightEscapingLayer:nil];
}

@end
