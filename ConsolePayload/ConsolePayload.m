//
//  ConsolePayload.m
//  ConsoleInjector
//
//  Created by Oleksiy Ivanov on 07/09/2013.
//  Copyright (c) 2013 Oleksiy Ivanov.
//  The MIT License (MIT). See LICENSE file.
//

#import <objc/runtime.h>

#import "ConsolePayload.h"

// do not search for identifier longer than this number of characters
const NSUInteger maxPositionOfMatchedIdentifier = 256;

#pragma mark Methods overriding
// Code from http://www.mikeash.com/pyblog/friday-qa-2010-01-29-method-replacement-for-fun-and-profit.html
static void MethodSwizzle(Class c, SEL origSEL, SEL overrideSEL)
{
    Method origMethod = class_getInstanceMethod(c, origSEL);
    Method overrideMethod = class_getInstanceMethod(c, overrideSEL);

    //NSLog(@"orig=%p, override=%p overridesSEL: %@", origMethod, overrideMethod, NSStringFromSelector(overrideSEL));

    if(class_addMethod(c, origSEL, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod))) {
        class_replaceMethod(c, overrideSEL, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, overrideMethod);
    }
}

static void OverrideClass(const char *name, SEL origSEL, Method overrideMethod) {
    Class c = objc_getClass(name);
    if (c != nil) {
        // add override method to target class
        if (!class_addMethod(c,
                             method_getName(overrideMethod),
                             method_getImplementation(overrideMethod),
                             method_getTypeEncoding(overrideMethod))) {
            NSLog (@"Method add failed");
        }
        // swizzle methods
        MethodSwizzle(c, origSEL, method_getName(overrideMethod));
        //NSLog(@"Method overriden in class %s", name);
    } else {
        NSLog(@"Class %s not found to override", name);
    }
}

#pragma mark Types descriptions
@interface ASLMessage : NSObject

- (NSString *)message;
- (id)sender;

@end

@interface MessageItemCellView : NSTableCellView
{
    NSTextField *_messageField;
}

- (ASLMessage *)msg;

@end

@interface LogController : NSWindowController
{
    NSTextView *_textView;
}

- (void)_logFileChanged;
- (void)_reload;
- (void)_sidebarItemDidChangeNotification:(id)arg1;

@end

@implementation ConsolePayload

#pragma mark Default attributes mappings
+ (NSArray *)attributesMappingsArray
{
    static NSArray *array = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        NSDictionary *errorAttr = @{NSForegroundColorAttributeName:[NSColor redColor], NSBackgroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.9 alpha:1]};
        NSDictionary *warningAttr = @{NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:0.6 green:0.6 blue:0.1 alpha:1]};
        NSDictionary *infoAttr = @{
                                   NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:0.2 green:0.6 blue:0.2 alpha:1]
                                   };
        NSDictionary *verboseAttr = @{NSForegroundColorAttributeName:[NSColor darkGrayColor]};
        NSDictionary *debugAttr = @{NSForegroundColorAttributeName:[NSColor blackColor]};

        // mappings are added to array in order of priority
        array = @[
                  /* Console internal attributes */
                  @{@"key": @"Marker -", @"attr":@{
                      NSForegroundColorAttributeName:[NSColor blackColor],
                      NSBackgroundColorAttributeName:[NSColor lightGrayColor]
                      }},
                  /* Custom codes */

                  /* Insert custom codes here */

                  // test attribute, highlight message made by this App
                  @{@"key":@"ConsolePayload",
                    @"attr":@{
                            NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:0.2 green:0.2 blue:0.6 alpha:1],
                            NSUnderlineStyleAttributeName:@YES,
                            NSUnderlineColorAttributeName:[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:1 alpha:1],
                            NSBackgroundColorAttributeName:[NSColor lightGrayColor]
                            }
                    },

                  @{@"key":@"GUEST:",
                    @"attr":@{
                            NSForegroundColorAttributeName:[NSColor colorWithCalibratedRed:0.2 green:0.2 blue:0.6 alpha:1],
                            NSUnderlineStyleAttributeName:@YES,
                            NSUnderlineColorAttributeName:[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:1 alpha:1]
                            }
                    },

                  /* Error codes */
                  @{ @"key":@"/ERRO", @"attr":errorAttr},
                  @{ @"key":@"|Error|", @"attr":errorAttr},
                  @{ @"key":@"<Error>:", @"attr":errorAttr},
                  @{ @"key":@"ERROR:", @"attr":errorAttr},
                  @{ @"key":@"[ERROR]", @"attr":errorAttr},

                  /* Warning codes */
                  @{ @"key":@"/WARN", @"attr":warningAttr},
                  @{ @"key":@"<Warn>:", @"attr":warningAttr},
                  @{ @"key":@"|Warning|", @"attr":warningAttr},
                  @{ @"key":@"[WARN]", @"attr":warningAttr},

                  /* Info codes */
                  @{ @"key":@"/info", @"attr":infoAttr},
                  @{ @"key":@"|Info|", @"attr":infoAttr},
                  @{ @"key":@"<Info>:", @"attr":infoAttr},
                  @{ @"key":@"[INFO]:", @"attr":infoAttr},

                  /* Verbose codes */
                  @{ @"key":@"/verb", @"attr":verboseAttr},
                  @{ @"key":@"<Verbose>:", @"attr":verboseAttr},

                  /* Debug */
                  @{ @"key":@"<Debug>:", @"attr":debugAttr}
                  ];
    });
    return array;
}

#pragma mark Replacement methods
- (void)replaced_viewWillDraw
{
    MessageItemCellView* cellView = (id)self;

    Ivar ivarMsgField = class_getInstanceVariable([cellView class], "_messageField");
    NSTextField *textField = object_getIvar(cellView, ivarMsgField);

    ASLMessage *message = [cellView msg];

    NSString *messageContent = [message message];

    NSDictionary *attrs = [ConsolePayload attributesForMessageString:messageContent];

    [textField setTextColor:[attrs objectForKey:NSForegroundColorAttributeName]];
    [textField setBackgroundColor:[attrs objectForKey:NSBackgroundColorAttributeName]]; // this looks like not working

    [self replaced_viewWillDraw]; // call original method
}

- (void)replaced_logFileChanged
{
    LogController* logController = (id)self;

    [self replaced_logFileChanged]; // call original method

    Ivar ivarTextView = class_getInstanceVariable([logController class], "_textView");
    NSTextView *textView = object_getIvar(logController, ivarTextView);

    [ConsolePayload applyAttributesToTextView:textView];
}

- (void)replaced_reload
{
    LogController* logController = (id)self;

    //NSLog(@"Called replaced_reload, self [%@].",logController);

    [self replaced_reload]; // call original method

    Ivar ivarTextView = class_getInstanceVariable([logController class], "_textView");
    NSTextView *textView = object_getIvar(logController, ivarTextView);

    [ConsolePayload applyAttributesToTextView:textView];
}

- (void)replaced_sidebarItemDidChangeNotification:(id)arg1
{
    //arg here FileSidebarItem

    //LogController* logController = (id)self;

    //NSLog(@"Called replaced_sidebarItemDidChangeNotification, self [%@], arg [%@].", logController, arg1);

    [self replaced_sidebarItemDidChangeNotification:arg1]; // call original method
}

#pragma mark Internal methods
+ (void)overrideMethods
{
    Method method;

    method = class_getInstanceMethod(self, @selector(replaced_viewWillDraw));
    OverrideClass("MessageItemCellView", @selector(viewWillDraw), method);

    method = class_getInstanceMethod(self, @selector(replaced_logFileChanged));
    OverrideClass("LogController", @selector(_logFileChanged), method);
    method = class_getInstanceMethod(self, @selector(replaced_reload));
    OverrideClass("LogController", @selector(_reload), method);
    method = class_getInstanceMethod(self, @selector(replaced_sidebarItemDidChangeNotification:));
    OverrideClass("LogController", @selector(_sidebarItemDidChangeNotification:), method);
}

+ (BOOL)stringExistsInMessageStringWithSearchString:(NSString *)searchString withMessageString:(NSString *)messageString
{
    BOOL exists = [messageString rangeOfString:searchString options:NSLiteralSearch range:NSMakeRange(0, MIN([messageString length]-1,maxPositionOfMatchedIdentifier))].length>0;
    return exists;
}

+ (NSDictionary *)attributesForMessageString:(NSString *)string
{
    NSArray *mappingsArray = [self attributesMappingsArray];
    NSEnumerator *enumerator = [mappingsArray objectEnumerator];
    NSDictionary *mapping;
    while ((mapping = [enumerator nextObject])) {
        if ([ConsolePayload stringExistsInMessageStringWithSearchString:mapping[@"key"] withMessageString:string]) {
            NSDictionary *attr = mapping[@"attr"];
            return attr;
        }
    }

    return nil;
}

+ (void)applyAttributesToTextView:(NSTextView *)textView
{
    if (![textView isRichText]) {
        [textView setRichText:YES];
    }

    // save current font
    NSFont *font = [[textView textStorage]font];

    // apply new attributes
    NSString *string = [textView string];
    [[textView textStorage]setAttributedString:[ConsolePayload attributedStringForString:string]];

    // restore font
    [[textView textStorage]setFont:font];
}

+ (NSAttributedString *)attributedStringForString:(NSString *)string
{
    NSMutableAttributedString * attrString = [[NSMutableAttributedString alloc]initWithString:string];
    
    NSUInteger numberOfLines, index, stringLength = [string length];
    for (index = 0, numberOfLines = 0; index < stringLength; numberOfLines++) {

        NSRange rangeForLine = [string lineRangeForRange:NSMakeRange(index, 0)];
        index = NSMaxRange(rangeForLine);

        NSString *line = [string substringWithRange:rangeForLine];
        NSDictionary *attrForLine = [ConsolePayload attributesForMessageString:line];
        [attrString setAttributes:attrForLine range:rangeForLine];
    }
    return attrString;
}

#pragma mark Initialization
+ (void)load
{
    NSLog(@"ConsolePayload loaded. Pid %d",getpid());

    [self overrideMethods];
}

@end
