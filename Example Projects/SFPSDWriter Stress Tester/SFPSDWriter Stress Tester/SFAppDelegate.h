//
//  SFAppDelegate.h
//  SFPSDWriterStressTest
//
//  Created by Konstantin Erokhin on 13/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SFPSDWriter.h"

@interface SFAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong) SFPSDWriter *writer;

- (IBAction)addLayer:(id)sender;
- (IBAction)writePSD:(id)sender;
- (IBAction)clearPSDWriter:(id)sender;

- (IBAction)add10Layers:(id)sender;
- (IBAction)add100Layers:(id)sender;
- (IBAction)writePSD10Times:(id)sender;
- (IBAction)changeImageSize:(id)sender;

- (IBAction)addTopEscapingLayer:(id)sender;
- (IBAction)addBottomEscapingLayer:(id)sender;
- (IBAction)addLeftEscapingLayer:(id)sender;
- (IBAction)addRightEscapingLayer:(id)sender;

- (IBAction)addAllEscapingLayers:(id)sender;
@end
