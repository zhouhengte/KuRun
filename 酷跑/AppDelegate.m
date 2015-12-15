//
//  AppDelegate.m
//  酷跑
//
//  Created by mis on 15/12/3.
//  Copyright © 2015年 tarena. All rights reserved.
//

#import "AppDelegate.h"
#import <BaiduMapAPI_Map/BMKMapComponent.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //初始化mapManager对象
    self.mapManager = [[BMKMapManager alloc] init];
    //授权(key)
    [self.mapManager start:@"uzfW9sC419T1wSfvXXBjcvQf" generalDelegate:self];

    
    [self setThme];
    return YES;
}

/** 百度地图联网状态 */
-(void)onGetNetworkState:(int)iError
{
    if (iError == 0) {
        MYLog(@"百度地图联网成功");
    }else{
        MYLog(@"onGetNetworkState %d",iError);
    }
}

/** 授权状态 */
-(void)onGetPermissionState:(int)iError
{
    if (iError == 0) {
        MYLog(@"百度地图授权成功");
    }else{
        MYLog(@"onGetPermissionState %d",iError);
    }
}

/* 设置导航栏的统一样式 */
-(void) setThme
{
    // 设置导航栏背景
    UINavigationBar *bar = [UINavigationBar appearance];
    [bar setBackgroundImage:[UIImage imageNamed:@"矩形"] forBarMetrics:UIBarMetricsDefault];
    bar.barStyle = UIBarStyleBlack;
    bar.tintColor = [UIColor whiteColor];
}




- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
