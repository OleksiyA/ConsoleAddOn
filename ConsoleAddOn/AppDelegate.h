//
//  AppDelegate.h
//  ConsoleAddOn
//
//  Created by Oleksiy Ivanov on 13/09/2013.
//  Copyright (c) 2013 Oleksiy Ivanov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *toggleInstallButton;
@property (weak) IBOutlet NSTextField *installationStatusTextLabel;

- (IBAction)ontoggleInstallButtonClicked:(NSButton *)sender;
@end
