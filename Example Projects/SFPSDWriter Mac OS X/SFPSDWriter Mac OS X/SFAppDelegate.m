//
//  SFAppDelegate.m
//  SFPSDWriter Mac OS X
//
//  Created by Konstantin Erokhin on 12/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//

#import "SFAppDelegate.h"

#import "SFPSDWriter.h"

@implementation SFAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // The images we want to insert in the PSD
    NSImage *firstImage = [NSImage imageNamed:@"firstImage"];
    NSImage *secondImage = [NSImage imageNamed:@"secondImage"];
    
    // SFPSDWriter instance
    SFPSDWriter *psdWriter = [[SFPSDWriter alloc] initWithDocumentSize: NSSizeToCGSize(firstImage.size)];
    
    // We want all our layers to be included in a group...
    SFPSDGroupOpeningLayer *firstGroup = [psdWriter openGroupLayerWithName:@"We ♥ groups!"];
    
    // ... and the group should be open at file opening
    [firstGroup setIsOpened:YES];
    
    // Adding the first image layer
    [psdWriter addLayerWithCGImage:[[[firstImage representations] objectAtIndex:0] CGImage]
                           andName:@"First Layer"
                        andOpacity:1
                         andOffset:NSMakePoint(0, 0)];
    
    // I mean, we really love groups
    // This time we don't need to change group's attributes so we don't store the reference
    [psdWriter openGroupLayerWithName:@"You'll have to open me!"];
    
    // The second image will be in the second group, offsetted by (116px, 66px), semi-transparent...
    SFPSDLayer *secondLayer = [psdWriter addLayerWithCGImage:[[[secondImage representations] objectAtIndex:0] CGImage]
                                                     andName:@"Second Layer"
                                                  andOpacity:0.5
                                                   andOffset:NSMakePoint(116, 66)];
    
    // ... and with "Darken" blend mode
    [secondLayer setBlendMode:SFPSDLayerBlendModeDarken];
    
    // We have to close every group we've opened
    [psdWriter closeCurrentGroupLayer]; // second group
    [psdWriter closeCurrentGroupLayer]; // first group
    
    // We'll write our test file to the Desktop
    NSString *basePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"];
    NSString *fullFilePath = [basePath stringByAppendingPathComponent:@"SFPSDWriter Test File.psd"];
    
    // Retrieving the PSD data
    NSData * psd = [psdWriter createPSDData];
    
    // Writing the data on disk
    [psd writeToFile:fullFilePath atomically:NO];
    
    // Opening the newly created file! :)
    [[NSWorkspace sharedWorkspace] openFile:fullFilePath];
}

@end
