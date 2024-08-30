//
//  OCRhea.m
//  RheaTime
//
//  Created by phoenix on 2023/4/3.
//

#import "OCRhea.h"

__attribute__((constructor)) static void premain(void) {
    [NSClassFromString(@"RheaTime.Rhea") performSelector:@selector(rhea_premain)];
}

@implementation OCRhea

+ (void)load {
    [NSClassFromString(@"RheaTime.Rhea") performSelector:@selector(rhea_load)];
}
@end
