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
    self.writer = [[SFPSDWriter alloc] initWithDocumentSize:CGSizeMake(1000, 1000)];
}

- (IBAction)addLayer:(id)sender {
    CGImageRef image = [[[[NSImage imageNamed:@"layerImage"] representations] objectAtIndex:0] CGImage];
    // CGImageRef imageCMYK = [[[[NSImage imageNamed:@"layerImageCMYK"] representations] objectAtIndex:0] CGImage];
    
    int wOffsetR = arc4random() % 740;
    int hOffsetR = arc4random() % 790;
    
    CGPoint offset = CGPointMake(wOffsetR, hOffsetR);
    
    NSString *name = [NSString stringWithFormat:@"random layer %ld", (unsigned long)([self.writer.layers count] + 1)];
    
    int opacityR = arc4random() % 100;
    
    float opacity = (float)opacityR / 100;
    
    [self.writer addLayerWithCGImage:image andName:name andOpacity:opacity andOffset:offset];
//    [self.writer addLayerWithCGImage:imageCMYK andName:name andOpacity:opacity andOffset:offset];
}

- (IBAction)writePSD:(id)sender {
    // We'll write our test file to the Desktop
    NSString *basePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"];
    NSString *fullFilePath = [basePath stringByAppendingPathComponent:@"SFPSDWriter Test File.psd"];
    
    // Retrieving the PSD data
    NSData * psd = [self.writer createPSDData];
    
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

- (IBAction)chanceImageSize:(id)sender {
    CGSize currentSize = [self.writer documentSize];
    currentSize.width = currentSize.width - 10;
    currentSize.height = currentSize.height - 10;
    [self.writer setDocumentSize:currentSize];
}

@end
