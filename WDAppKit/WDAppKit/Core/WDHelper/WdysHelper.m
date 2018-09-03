//
//  WdysHelper.m
//  SecretLocker
//
//  Created by 刘陶的mini on 2018/7/25.
//  Copyright © 2018年 apple. All rights reserved.
//
#import "IPTest.h"
#import "WDSaveHelper.h"
#import "AnalysisHelper.h"


#import "WdysHelper.h"
@implementation WdysHelper
/**
 苹果Ip检测：pad自动判断为苹果
 */
+(void)checkIp:(void(^)(BOOL isApple))complete{
    [IPTest checkIp:^(BOOL isApple) {
        BOOL isReviewing = NO;
        BOOL isPad =  [[UIDevice currentDevice].model isEqualToString:@"iPad"];
        if (isApple||isPad) {
            isReviewing = YES;
        }else{
            isReviewing = NO;
        }
        complete(isReviewing);
    } usingReivewFlag:YES];
}
/**
 三个平台：初始化
 */
+(void)initSDKWithAppID:(NSString*)appID launchOptions:(NSDictionary*)options{
    [[AnalysisHelper shared] initSDKWithAppID:appID launchOptions:options];
}
/**
 三个平台：购买成功
 */
+(void)trackPurChaseEventWithItemId:(NSString*)itemId AndPrice:(NSString*)price{
    [[AnalysisHelper shared] trackPurChaseEventWithItemId:itemId AndPrice:price];
}
/**
 三个平台：第一次购买、每天第一次购买
 */
+(void)trackKeyTimePurchaseEventWithEmail:(NSString*)email{
    [[AnalysisHelper shared] trackKeyTimePurchaseEventWithEmail:email];
}
/**
 三个平台：统计注册成功
 */
+(void)trackregistionEventWithEmail:(NSString*)email{
    [[AnalysisHelper shared] trackregistionEventWithEmail:email];
}
/**
 三个平台：统计登录成功
 */
+(void)trackLoginEventWithEmail:(NSString*)email{
    [[AnalysisHelper shared] trackLoginEventWithEmail:email];
}
/**
 我们的服务器：保存用户信息
 */
+(void)saveUserInfo:(NSString*)userInfo isPaySuccess:(BOOL)paySuccess{
    [WDSaveHelper saveUserInfo:userInfo isPaySuccess:paySuccess];
}
@end
