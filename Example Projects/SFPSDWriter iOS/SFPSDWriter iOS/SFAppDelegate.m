//
//  SFAppDelegate.m
//  SFPSDWriter iOS
//
//  Created by Konstantin Erokhin on 11/06/13.
//  Copyright (c) 2013 Shiny Frog. All rights reserved.
//

#import "SFAppDelegate.h"

#import "SFPSDWriter.h"

@implementation SFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // The images we want to insert in the PSD
    UIImage *firstImage = [UIImage imageNamed:@"firstImage"];
    UIImage *secondImage = [UIImage imageNamed:@"secondImage"];
    
    // SFPSDWriter instance
    SFPSDWriter *psdWriter = [[SFPSDWriter alloc] initWithDocumentSize:firstImage.size andResolution:300.0 andResolutionUnit:SFPSDResolutionUnitPPI];
    
    // We want all our layers to be included in a group...
    SFPSDGroupOpeningLayer *firstGroup = [psdWriter openGroupLayerWithName:@"We ♥ groups!"];
    
    // ... and the group should be open at file opening
    [firstGroup setIsOpened:YES];
    
    // Adding the first image layer
    [psdWriter addLayerWithCGImage:[firstImage CGImage]
                           andName:@"First Layer"
                        andOpacity:1
                         andOffset:CGPointMake(0, 0)];
    
    // I mean, we really love groups
    // This time we don't need to change group's attributes so we don't store the reference
    [psdWriter openGroupLayerWithName:@"You'll have to open me!"];
    
    // The second image will be in the second group, offsetted by (116px, 66px), semi-transparent...
    SFPSDLayer *secondLayer = [psdWriter addLayerWithCGImage:[secondImage CGImage]
                                                     andName:@"Second Layer"
                                                  andOpacity:0.5
                                                   andOffset:CGPointMake(116, 66)];
    
    // ... and with "Darken" blend mode
    [secondLayer setBlendMode:SFPSDLayerBlendModeDarken];

    // We'll prepare the Drop Shadow Effect Layer information
    SFPSDDropShadowEffectLayerInformation *dropShadowInformation = [[SFPSDDropShadowEffectLayerInformation alloc] init];
    dropShadowInformation.enabled = YES;
    dropShadowInformation.size = 100;
    dropShadowInformation.angle = 90;
    dropShadowInformation.distance = 5;
    dropShadowInformation.color = [[UIColor redColor] CGColor];
    dropShadowInformation.blendMode = SFPSDLayerBlendModeNormal;
    dropShadowInformation.useGlobalLight = NO;
    dropShadowInformation.opacity = 100;

    // We'll set the Drop Sahdow on the second layer (we can add it to the SFPSDGroupOpeningLayer too)
    [secondLayer setDropShadowEffectLayerInformation:dropShadowInformation];

    // Other available Effect Layers are:
    // - Inner Shadow (SFPSDInnerShadowEffectLayerInformation)
    // - Outer Glow (SFPSDOuterGlowEffectLayerInformation)
    // - Inner Glow (SFPSDInnerGlowEffectLayerInformation)
    // - Bevel (SFPSDBevelEffectLayerInformation)
    // - Solid Fill (SFPSDSolidFillEffectLayerInformation)

    // We have to close every group we've opened
    [psdWriter closeCurrentGroupLayer]; // second group
    [psdWriter closeCurrentGroupLayer]; // first group

    // We can change the embedded color profile of the document (for example with an "sRGB IEC61966-2.1")
    [psdWriter setColorProfile:SFPSDSRGBColorProfile];

    // We'll write our test file into the documents folder of the application
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *fullFilePath = [documentsDirectory stringByAppendingPathComponent:@"SFPSDWriter Test File.psd"];
    
    // Retrieving the PSD data
    NSError *error = nil;
    NSData *psd = [psdWriter createPSDDataWithError:&error];
    
    // Checking for errors
    if (nil != error) {
        NSLog(@"There was an error writing the PSD: %@", [error description]);
        return;
    }
    
    // Writing the data on disk
    // When using the simulator we can find the file in
    // /Users/<Username>/Library/Application\ Support/iPhone\ Simulator/<Simulator Version>/Applications/<Application>/Documents
    [psd writeToFile:fullFilePath atomically:NO];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
