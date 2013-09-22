//
//  main.m
//  ConsoleInjector
//
//  Created by Oleksiy Ivanov on 06/09/2013.
//  Copyright (c) 2013 Oleksiy Ivanov.
//  The MIT License (MIT). See LICENSE file.
//

#import <Foundation/Foundation.h>

#import "ConsoleInjector.h"

int main(int argc, const char * argv[])
{
    __autoreleasing __unused ConsoleInjector *injector = [[ConsoleInjector alloc]init];
    
    // starting runloop
    [[NSRunLoop currentRunLoop] run];
    
    
    return 0;
}

