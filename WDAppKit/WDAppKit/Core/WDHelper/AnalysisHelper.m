//
//  AnalysisHelper.m
//  HollaVideo
//
//  Created by 刘陶的mini on 2018/6/25.
//  Copyright © 2018年 apple. All rights reserved.
//

#import "AnalysisHelper.h"
#import <AdSupport/AdSupport.h>
@implementation AnalysisHelper
+(AnalysisHelper*)shared{
    static dispatch_once_t pred;
    static AnalysisHelper *instance;
    dispatch_once(&pred, ^{
        instance = [[AnalysisHelper alloc] init];
        
    });
    return instance;
}

-(void)initSDKWithAppID:(NSString*)appID launchOptions:(NSDictionary*)options{
    //firebase启动
    [FIRApp configure];
    //faceBooke启动
    [[FBSDKApplicationDelegate sharedInstance] application:[UIApplication sharedApplication]
                             didFinishLaunchingWithOptions:options];
    [FBSDKAppEvents activateApp];
    //appsFlyer启动
    [AppsFlyerTracker sharedTracker].appsFlyerDevKey = @"hZ6ZwBJWkaXUERqoFiWCSV";
    [AppsFlyerTracker sharedTracker].appleAppID = appID;
    //添加通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}
-(void)trackPurChaseEventWithItemId:(NSString*)itemId AndPrice:(NSString*)price{
    //facebook 统计
    [FBSDKAppEvents logPurchase:[price floatValue] currency:@"USD"];
    // appsflyer添加统计
    [[AppsFlyerTracker sharedTracker] trackEvent:AFEventPurchase withValues: @{AFEventParamContentId:itemId,
             AFEventParamContentType : @"category_a", AFEventParamRevenue: price,
           AFEventParamCurrency:@"USD"}];
    //google统计
    [FIRAnalytics logEventWithName:kFIREventEcommercePurchase
                        parameters:@{
                                     kFIRParameterItemID:itemId,
                                     kFIRParameterValue : [NSNumber numberWithFloat:price.floatValue],
                                     kFIRParameterCurrency : @"USD",
                                     }];
}
//首次付费、一个用户终身只记录一次
//每日充值、每天记录第一次付费
-(void)trackKeyTimePurchaseEventWithEmail:(NSString*)email{
    if (email==nil||email.length<1||[email isEqual:@""]||[email isKindOfClass: [NSNull class]]) {
        NSString * idfaString = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        email = idfaString;
    }
    NSString * userEmail = email;
    //首次付费、一个用户终身只记录一次
    BOOL firstPurchase =   [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"firstPurchase%@",userEmail]];
    if (firstPurchase==NO) {
        [[AppsFlyerTracker sharedTracker] trackEvent:@"FirstPurchase" withValues:@{ @"firstPurchase_event": userEmail}];
        [FBSDKAppEvents logEvent:@"FirstPurchase" parameters:@{ @"firstPurchase_event": userEmail}];
        [FIRAnalytics logEventWithName:@"FirstPurchase" parameters:@{ kFIRParameterItemName: userEmail}];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:[NSString stringWithFormat:@"firstPurchase%@",userEmail]];
    }
    //每日充值、每天记录第一次付费
    NSDate * date =  [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"dailyFirstpurchase%@",userEmail]];
    NSDate * nowDate = [NSDate date];
    BOOL isSameDay = [[NSCalendar currentCalendar] isDate:date inSameDayAsDate:nowDate];
    if (date==nil||isSameDay==NO) {
        [[AppsFlyerTracker sharedTracker] trackEvent:@"DailyFirstPurchase" withValues:@{ @"dailyFirstPurchase_email": userEmail}];
        [FBSDKAppEvents logEvent:@"DailyFirstPurchase" parameters:@{ @"dailyFirstPurchase_email": userEmail}];
        [FIRAnalytics logEventWithName:@"DailyFirstPurchase" parameters:@{ kFIRParameterItemName: userEmail}];
        
        [[NSUserDefaults standardUserDefaults] setObject:nowDate forKey:[NSString stringWithFormat:@"dailyFirstpurchase%@",userEmail]];
    }
}
 //注册成功统计邮箱
-(void)trackregistionEventWithEmail:(NSString*)email{
    if (email==nil||email.length<1||[email isEqual:@""]||[email isKindOfClass: [NSNull class]]) {
        NSString * idfaString = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        email = idfaString;
    }
    [[AppsFlyerTracker sharedTracker] trackEvent:@"RegisterSuccess" withValues:@{ AFEventCompleteRegistration: email}];
    [FBSDKAppEvents logEvent:@"RegisterSuccess" parameters:@{ FBSDKAppEventNameCompletedRegistration: email}];
    [FIRAnalytics logEventWithName:@"RegisterSuccess" parameters:@{ kFIRParameterItemName: email}];
    
  //REGISTRATIONSUCCESS
}
//登录成功统计邮箱
-(void)trackLoginEventWithEmail:(NSString*)email{
    if (email==nil||email.length<1||[email isEqual:@""]||[email isKindOfClass: [NSNull class]]) {
        NSString * idfaString = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        email = idfaString;
    }
    //登录成功
    [[AppsFlyerTracker sharedTracker] trackEvent:@"LoginSuccess" withValues:@{ AFEventLogin: email}];
    [FBSDKAppEvents logEvent:@"LoginSuccess" parameters:@{ @"LoginEvent": email}];
    [FIRAnalytics logEventWithName:@"LoginSuccess" parameters:@{ kFIRParameterItemName: email}];
}


-(void)applicationDidBecomeActive{
     [[AppsFlyerTracker sharedTracker] trackAppLaunch];
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
