//
//  Rhea.m
//  Rhea
//
//  Created by phoenix on 2022/8/17.
//

#import "Rhea.h"
#import <objc/runtime.h>
#import <objc/message.h>

RheaTimeName const RheaTimeNameLoad = @"load";
RheaTimeName const RheaTimeNameAppDidFinishLaunching = @"appDidFinishLaunching";

@interface Rhea ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<NSString *> *> *methods;
@end

@implementation Rhea

+ (void)load {
    [[Rhea shared] sortMethodList];
    [[Rhea shared] triggerWithTime:RheaTimeNameLoad];
}

+ (instancetype)shared {
    static Rhea *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[Rhea alloc] _init];
    });
    return manager;
}

- (instancetype)_init {
    self = [super init];
    if (self) {
        _methods = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)sortMethodList {
    unsigned int methodListCount = 0;
    Method *methods = class_copyMethodList(Rhea.class, &methodListCount);
    for (NSInteger i = 0; i < methodListCount; i++) {
        Method method = methods[i];
        SEL name = method_getName(method);
        NSString *methodName = NSStringFromSelector(name);
        NSString *prefix = [self stringBeforUnderscoreWithString:methodName];
        if (!prefix || prefix.length == 0) {
            continue;
        }
        NSMutableArray<NSString *> *selectors = self.methods[prefix] ?: @[].mutableCopy;
        [selectors addObject:methodName];
        self.methods[prefix] = selectors;
    }
    free(methods);
}

- (void)triggerWithTime:(RheaTimeName)timeName {
    NSArray<NSString *> *methods = self.methods[timeName];
    if (!methods || methods.count == 0) {
        return;
    }
    for (NSString *method in methods) {
        SEL selector = NSSelectorFromString(method);
        if (selector) {
            ((id(*)(id,SEL))objc_msgSend)(self, selector);
        }
    }
}

- (nullable NSString *)stringBeforUnderscoreWithString:(NSString *)string {
    NSArray *array = [string componentsSeparatedByString:@"_"];
    if (array && array.count == 2) {
        return array[0];
    }
    return nil;
}

@end
