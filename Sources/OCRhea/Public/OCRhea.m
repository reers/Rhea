//
//  OCRhea.m
//  RheaTime
//
//  Created by phoenix on 2023/4/3.
//

#import "OCRhea.h"
//#import <RheaTime/RheaTime-Swift.h>

__attribute__((constructor)) static void premain(void) {
    NSLog(@"~~~~ premain oc rhea");
    [NSClassFromString(@"RheaTime.Rhea") performSelector:@selector(rhea_premain)];
//    [Rhea rhea_premain];
}

@interface OCRhea ()
@property (class, nonatomic, strong) Class rheaClas;
@end

@implementation OCRhea

+ (Class)rheaClas {
    return NSClassFromString(@"RheaTime.Rhea");
}

+ (void)load {
    NSLog(@"~~~~load oc rhea");
//    [Rhea rhea_load];
    [self.rheaClas performSelector:@selector(rhea_load)];
}

+ (void)keep {
    NSLog(@"~~~~ keep");
}
@end
