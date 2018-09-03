//
//  SaveAppInfo.h
//  liuTaoLiveGirl
//
//  Created by 刘陶的mini on 2018/7/4.
//  Copyright © 2018年 ICSOFT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WDSaveHelper : NSObject
/*
 使用：
 马甲包、正式包：
 注册、登录、购买成功之后调用次方法。
 
 
 userInfo ： 传入用户的邮箱/facebookId
 paySuccess ：购买成功后为YES，其他情况为NO
 
 
 无账号的app： userInfo传入nil 
 
 */
+(void)saveUserInfo:(NSString*)userInfo isPaySuccess:(BOOL)paySuccess;
@end
