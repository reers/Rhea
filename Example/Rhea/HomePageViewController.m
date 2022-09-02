//
//  HomePageViewController.m
//  Rhea_Example
//
//  Created by phoenix on 2022/8/13.
//  Copyright © 2022 phoenix. All rights reserved.
//

#import "HomePageViewController.h"

@import RheaTime;

@interface HomePageViewController ()

@end

@implementation HomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

+ (void)doSomethingWhenLoad {
    NSLog(@"HomePageViewController doSomethingWhenLoad");
}

+ (void)doSomethingWhenAppDidFinishLaunching {
    NSLog(@"HomePageViewController doSomethingWhenAppDidFinishLaunching");
}

@end


RheaTimeBegin(HomePageViewController)
- (void)load_homePageViewController {
    [HomePageViewController doSomethingWhenLoad];
}

- (void)appDidFinishLaunching_homePageViewController {
    [HomePageViewController doSomethingWhenAppDidFinishLaunching];
}

- (void)mainViewControllerDidAppear_homePageViewController {
    NSLog(@"HomePageViewController doSomethingWhenMainViewControllerDidAppear");
}
RheaTimeEnd
