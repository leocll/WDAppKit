//
//  WdysHelper.h
//  SecretLocker
//
//  Created by 刘陶的mini on 2018/7/25.
//  Copyright © 2018年 apple. All rights reserved.
//




#import <Foundation/Foundation.h>

@interface WdysHelper : NSObject

//公司ip检测、pad自动判断为审核状态-启动
+(void)checkIp:(void(^)(BOOL isApple))complete;
//三方统计、初始化三方平台统计
+(void)initSDKWithAppID:(NSString*)appID launchOptions:(NSDictionary*)options;
//三方统计、购买--购买成功后统计
+(void)trackPurChaseEventWithItemId:(NSString*)itemId AndPrice:(NSString*)price;
 //三个统计、购买--购买成功后统计
+(void)trackKeyTimePurchaseEventWithEmail:(NSString*)email;
//三方统计、注册
+(void)trackregistionEventWithEmail:(NSString*)email;
//三方统计、登录
+(void)trackLoginEventWithEmail:(NSString*)email;
//公司统计、注册、登录、购买成功后统计
+(void)saveUserInfo:(NSString*)userInfo isPaySuccess:(BOOL)paySuccess;

@end
