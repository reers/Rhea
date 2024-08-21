//
//  OCRhea.m
//  RheaTime
//
//  Created by phoenix on 2023/4/3.
//

#import "OCRhea.h"
#import <RheaTime/RheaTime-Swift.h>

__attribute__((constructor)) static void premain(void) {
    NSLog(@"~~~~ premain oc rhea");
    [Rhea rhea_premain];
}

@implementation OCRhea
+ (void)load {
    NSLog(@"~~~~load oc rhea");
    [Rhea rhea_load];
}
@end
