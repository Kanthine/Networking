//
//  AppDelegate.m
//  Networking
//
//  Created by 苏沫离 on 2020/6/3.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "AppDelegate.h"
#import "ItemListTableController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
    
    ItemListTableController *vc = [[ItemListTableController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = nav;
    
    return YES;
}

@end
