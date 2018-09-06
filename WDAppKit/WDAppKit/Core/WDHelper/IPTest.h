//
//  IPTest.h
//  Secondnumber
//
//  Created by chenliyang on 28/03/2018.
//  Copyright © 2018 SecondNumber. All rights reserved.
//

#import <Foundation/Foundation.h>

//检测到时苹果的IP,count += 10
//非苹果的IP,count --
//假如count > 0 ,返回YES,但是仍然会继续检测
typedef void (^IPTestCompletionHandler)(BOOL);
@interface IPTest : NSObject
{
    IPTestCompletionHandler _completion;//handler
    NSMutableSet *_citys;
    NSInteger _taskCount;//任务数
    NSThread *_currentThread;//被调用线程
    NSString *_launch;
    NSString *_app_version;
    NSString *_bundleId;
    BOOL _usingReviewFlag;
    BOOL _timeOut;
    
    unsigned char* _blacks;
    int _blackCount;
}
@property(atomic,readwrite) BOOL result;
+ (void) checkIp:(void (^)(BOOL isApple))completion usingReivewFlag:(BOOL)usingflag;
//usingReviewFlag说明
//当usingReviewFlag=NO的时候，不判断是否是审核的版本
//当usingReviewFlag=YES
//从"https://s3-us-west-2.amazonaws.com/ip-test-config/" + bundleId获取配置文件，例如小号的配置文件地址是
//https://s3-us-west-2.amazonaws.com/ip-test-config/com.secondphone.sp
//s3的亚马逊账号是建虚拟机的那个账号,用户名：wudiyongshi,文件夹是ip-test-config    （8月31日更新）
//配置文件有三种内容
//版本号，例如1.3.2  或者   1   或者  0
//当文件内容是版本号，那么客户端版本号与它相等的时候，判断是审核状态
//当文件内容是1，所有客户端版本都认为是审核状态
//当文件内容是0，所有客户端版本都认为是非审核状态

//判定为非审核状态时，ip判断依然生效

//一旦某次获取到配置的内容是0，这个版本就不会再去获取配置了，也就是说，以后配置从0改成1，对老用户没用影响

@end

