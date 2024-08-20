//
//  OCRhea.m
//  RheaTime
//
//  Created by phoenix on 2023/4/3.
//

#import "OCRhea.h"
#import <RheaTime/RheaTime-Swift.h>

__attribute__((constructor)) static void premain(void) {
    [Rhea rhea_premain];
}

@implementation OCRhea
+ (void)load {
    [Rhea rhea_load];
}
@end
