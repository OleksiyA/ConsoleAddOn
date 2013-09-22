//
//  ConsoleInjector.m
//  ConsoleInjector
//
//  Created by Oleksiy Ivanov on 9/19/13.
//  Copyright (c) 2013 Oleksiy Ivanov.
//  The MIT License (MIT). See LICENSE file.
//

#import <AppKit/AppKit.h>
#import <mach_inject_bundle/mach_inject_bundle.h>

#import "ConsoleInjector.h"

#define K_appBundleIdentifier @"com.apple.Console"

void injectConsoleApp(NSString *payloadBundlePath)
{
    //check is bundle payload exists
    if (![[NSFileManager defaultManager]fileExistsAtPath:payloadBundlePath]) {
        NSLog(@"Can't locate payload bundle at [%@].", payloadBundlePath);
        return;
    }
    
    NSString *identifier = K_appBundleIdentifier;
    
    NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier: identifier];
    if (apps.count == 0) {
        NSLog(@"Couldn't find the app");
        return;
    }
    
    NSLog(@"Arch of the app is %p", (void*)[[apps lastObject]executableArchitecture]);
    
    pid_t pid = [[apps lastObject] processIdentifier];
    
    if (pid <= 0) {
        NSLog(@"Couldn't find the pid");
        return;
    }
    
    mach_error_t err = mach_inject_bundle_pid([payloadBundlePath fileSystemRepresentation], pid);
    
    if (!err) {
        NSLog(@"Successfully injected '%@' into %@ (%d)", payloadBundlePath, identifier, pid);
        return;
    } else {
        NSLog(@"Injection of '%@' into %@ (%d) failed, err %d", payloadBundlePath, identifier, pid, err);
        return;
    }
}

@implementation ConsoleInjector

#pragma mark Internal interface
- (void)handleAppStarted
{
    NSString *payloadBundlePath = @"/Users/oleksiyivanov/Library/Developer/Xcode/DerivedData/ConsoleInjector-djjanskiylvclbfhksbxiodvheug/Build/Products/Debug/ConsolePayload.bundle";
    injectConsoleApp(payloadBundlePath);
}

- (void)checkForStartedConsoleApp
{
    if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:K_appBundleIdentifier]count]) {
        NSLog(@"Detected running Console App");
        [self handleAppStarted];
    }
}

- (void)subscribeToNotifications
{
    [[[NSWorkspace sharedWorkspace] notificationCenter]addObserver:self selector:@selector(onAppLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
}

- (void)unsubscribeFromNotifications
{
    [[[NSWorkspace sharedWorkspace] notificationCenter]removeObserver:self];
}

- (void)onAppLaunched:(NSNotification *)notification
{
    NSRunningApplication *app = notification.userInfo[NSWorkspaceApplicationKey];
    
    NSString *bundleId = app.bundleIdentifier;
    
    NSLog(@"Detected Console App start.");
    
    if ([bundleId isEqualToString:K_appBundleIdentifier]) {
        [self handleAppStarted];
    }
}

#pragma mark Allocation and Deallocation
- (instancetype)init
{
    if (self = [super init]) {
        [self subscribeToNotifications];
        [self checkForStartedConsoleApp];
    }
    return self;
}

- (void)dealloc
{
    [self unsubscribeFromNotifications];
}

@end
