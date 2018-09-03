//
//  AnalysisHelper.h
//  HollaVideo
//
//  Created by 刘陶的mini on 2018/6/25.
//  Copyright © 2018年 apple. All rights reserved.
//


#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit/FBSDKAppEvents.h>
#import <AppsFlyerFramework/AppsFlyerLib/AppsFlyerTracker.h>
#import <Firebase.h>
//@import Firebase;

#import <Foundation/Foundation.h>

@interface AnalysisHelper : NSObject<UIApplicationDelegate>
+(AnalysisHelper*)shared;
/**
 在应用启动的时候，初始化三个平台的统计
 */
-(void)initSDKWithAppID:(NSString*)appID launchOptions:(NSDictionary*)options;
/**
 购买成功、统计价格
 */
-(void)trackPurChaseEventWithItemId:(NSString*)itemId AndPrice:(NSString*)price;
//首次付费、一个用户终身只记录一次
//每日充值、每天记录第一次付费
-(void)trackKeyTimePurchaseEventWithEmail:(NSString*)email;
/**
 注册成功、统计邮箱
 */
-(void)trackregistionEventWithEmail:(NSString*)email;
/**
登录成功、统计邮箱
 */
-(void)trackLoginEventWithEmail:(NSString*)email;
@end
