//
//  AppDelegate.m
//  ConsoleAddOn
//
//  Created by Oleksiy Ivanov on 13/09/2013.
//  Copyright (c) 2013 Oleksiy Ivanov. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

#pragma mark Internal methods


#pragma mark AppDelegate methods
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

#pragma mark Events handling
- (IBAction)ontoggleInstallButtonClicked:(NSButton *)sender {
 
    NSLog(@"On install clicked.");
    
}

@end
