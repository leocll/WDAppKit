//
//  SaveAppInfo.m
//  liuTaoLiveGirl
//
//  Created by 刘陶的mini on 2018/7/4.
//  Copyright © 2018年 ICSOFT. All rights reserved.
//
#import <AdSupport/AdSupport.h>
#import "WDSaveHelper.h"

@implementation WDSaveHelper
/*
 功能：
 1.统计IP地址
 2.统计登录、注册时候的邮箱
 3.统计广告标识符IDFA
 4.统计app名字
 5.统计购买成功后的IDFA
 */
+(void)saveUserInfo:(NSString*)userInfo isPaySuccess:(BOOL)paySuccess{
    NSString * idfaString = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    NSString * appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (idfaString==nil||appName==nil) {
        return;
    }
    //app没有用户账号的情况，userInfo即为用户的idfa
    if (userInfo==nil||userInfo.length<1) {
        userInfo = idfaString;
    }
    NSMutableDictionary * params = [NSMutableDictionary dictionary];
    params[@"email"] = userInfo;
    params[@"idfa"] = idfaString;
    params[@"app_name"] = appName;
    params[@"source"] = @"ios";
    params[@"is_pay"] = paySuccess ? @"1" : @"0";
    params[@"apptime"] = [NSString stringWithFormat:@"%0.0f",[[NSDate date] timeIntervalSince1970]];
    params[@"key"] = @"pCQ@Z*mznmxmdvdY@Uf&hcR$RItfzt4S";

    NSArray * array = @[params];
    //转json
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:nil];
    //加密json
    NSData *base64Data = [jsonData base64EncodedDataWithOptions:0];
    NSString *baseString = [[NSString alloc]initWithData:base64Data encoding:NSUTF8StringEncoding];

    NSURL *url = [NSURL URLWithString:@"http://saveemail.testwj.club/detail_save.php"];
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *args = [NSString stringWithFormat:@"signature=%@",baseString];
    request.HTTPBody = [args dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        if (data!=nil) {
//            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
//            NSLog(@"保存数据返回状态%@",dict);
//        }
    }];
    [sessionDataTask resume];
}
@end
