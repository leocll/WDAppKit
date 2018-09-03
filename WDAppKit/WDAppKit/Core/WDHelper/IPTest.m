//
//  IPTest.m
//  Secondnumber
//
//  Created by chenliyang on 28/03/2018.
//  Copyright © 2018 SecondNumber. All rights reserved.
//
//  2018.08.17
// 新增城市 San José
// 城市名称判断，从相等改为包含
// 本地简易的苹果IP库，来源是过去几个月后台数据库的数据
#import "IPTest.h"

static NSString* defaultConfig = @"{\"city\":[\"Menlo Park\",\"Cupertino\",\"San José\",\"San Jose\",\"Reno\"],\"link\":[{\"url\":\"https://ipapi.co/json/\",\"orgKey\":\"org\",\"orgValue\":\"apple\",\"ipKey\":\"ip\",\"type\":\"json\",\"key\":\"city\",\"encode\":\"utf8\"},{\"url\":\"https://api.db-ip.com/v2/free/self/\",\"ipKey\":\"ipAddress\",\"type\":\"json\",\"key\":\"city\",\"encode\":\"utf8\"}]}";
static NSString* serverAddress = @"https://s3-us-west-1.amazonaws.com/appconfigfiles/reviewconfig.txt";
//测试address:屏蔽香港IP
//https://s3-us-west-2.amazonaws.com/datingmenow/ip_limit_test/iptestdebug.json

//审核状态的配置文件所在文件夹，usingReviewFlag=YES时，生效
static NSString* reviewFlagPath = @"https://s3-us-west-2.amazonaws.com/ip-test-config/";

static NSString* recordServerUrl = @"http://saveemail.testwj.club/ip_record.php";

static NSString* IPTestUDKey = @"IPTestUDKey20180423";
#define TimeOutSeconds   5
//默认10秒超时

NSString *getUUID() {
    NSDictionary *query = @{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecReturnData : @YES,
                            (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitOne,
                            (__bridge id)kSecAttrAccount : @"user",
                            (__bridge id)kSecAttrService : @"uuid",
                            };
    CFTypeRef dataTypeRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &dataTypeRef);
    if (status == errSecSuccess) {
        NSString *uuid = [[NSString alloc] initWithData:(__bridge NSData * _Nonnull)(dataTypeRef) encoding:NSUTF8StringEncoding];
        return uuid;
    } else if (status == errSecItemNotFound) {
        NSDictionary *query = @{(__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlocked,
                                (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecValueData : [[[NSUUID UUID] UUIDString] dataUsingEncoding:NSUTF8StringEncoding],
                                (__bridge id)kSecAttrAccount : @"user",
                                (__bridge id)kSecAttrService : @"uuid",
                                };
        CFErrorRef error = NULL;
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, nil);
        
        return getUUID();
    } else {
        return nil;
    }
}

@implementation IPTest

- (id)init
{
    if([super init])
    {
        _citys = [NSMutableSet set];
        _currentThread = nil;
        _completion = nil;
        _result = NO;
        _timeOut = NO;
        
        _blacks = NULL;
        [self initIpBlacks];
    }
    return self;
}

+ (void) checkIp:(void (^)(BOOL isApple))completion usingReivewFlag:(BOOL)usingflag;//静态入口
{
    [[[IPTest alloc] init] checkIpHelper:completion usingReviewFlag:usingflag];
}

- (void)checkIpHelper:(void (^)(BOOL))completion usingReviewFlag:(BOOL)reivewFlag//入口
{
    _completion = completion;
    _usingReviewFlag = reivewFlag;
    _bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    _app_version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    _launch = [[NSUUID UUID] UUIDString];
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:IPTestUDKey] != nil)
    {
        if([[NSUserDefaults standardUserDefaults] integerForKey:IPTestUDKey] > 0)
        {
            completion(YES);
        }
        else
        {
            completion(NO);
        }
        _completion = nil;
    }
    
    _currentThread = [NSThread currentThread];
    [self createTimeOutTask];
    [NSThread detachNewThreadSelector:@selector(begin) toTarget:self withObject:nil];
}

- (void)pushResultOnCallThread//从原先的线程回调结果，出口
{
    if(_timeOut == NO)
    {
        if(_result)
        {
            [[NSUserDefaults standardUserDefaults] setInteger:10 forKey:IPTestUDKey];
        }
        else
        {
            NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:IPTestUDKey];
            count --;
            [[NSUserDefaults standardUserDefaults] setInteger:MAX(count,0) forKey:IPTestUDKey];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    if(_completion)
    {
        //NSLog(@"check_I_p is_A_p_p_l_e:%@",_result?@"YES":@"NO");
        _completion(_result);
        _completion = nil;
    }
}

- (void)pushResult:(BOOL)result//回调结果
{
    self.result = result;
    [self performSelector:@selector(pushResultOnCallThread) onThread:_currentThread withObject:nil waitUntilDone:NO];
}

- (void)begin//获取服务器config,获取失败 或者 使用服务器配置创建任务失败，那么使用默认配置创建任务
{
    if(_usingReviewFlag)
    {
        NSString *defaultsKey = [_bundleId stringByAppendingString:_app_version];
        if([[NSUserDefaults standardUserDefaults] objectForKey:defaultsKey] == nil)//一旦取到过0，那么该版本就不再去取了
        {
            NSString *flagUrl = [reviewFlagPath stringByAppendingString:_bundleId];
            NSError *error = nil;
            NSString *flag = [NSString stringWithContentsOfURL:[NSURL URLWithString:flagUrl] encoding:NSUTF8StringEncoding error:&error];
            if(error)
            {
                error = nil;
                flag = [NSString stringWithContentsOfURL:[NSURL URLWithString:flagUrl] encoding:NSUTF8StringEncoding error:&error];
            }
            if(error == nil && ([flag isEqualToString:@"1"] || [flag isEqualToString:_app_version]))
            {
                [self pushResult:true];
            }
            if([flag isEqualToString:@"0"])
            {
                //一旦取到过0，那么该版本就不再去取了
                [[NSUserDefaults standardUserDefaults] setObject:@"off" forKey:defaultsKey];
            }
        }
        
    }
    
    NSURL *configUrl = [NSURL URLWithString:serverAddress];
    NSError *error = nil;
    //默认使用NSUnicodeStringEncoding从服务器获取配置文件
    NSString *configString = [NSString stringWithContentsOfURL:configUrl
                                                      encoding:NSUTF8StringEncoding
                                                         error:&error];
    if(error)
    {
        NSLog(@"%@",error);
        if(error.domain == NSCocoaErrorDomain && error.code == 261)//编码格式错误，使用UTF8再尝试一次
        {
            error = nil;
            configString = [NSString stringWithContentsOfURL:configUrl encoding:NSUnicodeStringEncoding error:&error];
            if(error)
                NSLog(@"%@",error);
        }
    }
    if(error || [self createTask:configString] == false)//获取配置错误，或者，创建任务失败，使用默认配置创建任务
    {
        [self createTask:defaultConfig];
    }
}

- (NSString *)trimString:(NSString *)string//首先转化成小写字母，然后去除 除字母外 的其他字符
{
    string = [string lowercaseString];
    NSMutableString *outputString = [NSMutableString stringWithString:@""];
    for(int i = 0;i <[string length]; ++i)
    {
        unichar c = [string characterAtIndex:i];
        if(c >= 'a' && c <= 'z')
        {
            [outputString appendFormat:@"%c",c];
        }
    }
    return outputString;
}

- (BOOL)createTask:(NSString *)configString//先检查格式，假如正确，就创建任务
{
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:[configString              dataUsingEncoding:NSUTF8StringEncoding]
                                                    options:NSJSONReadingAllowFragments
                                                      error:&error];
    if(error)//配置文件创建Json失败
    {
        NSLog(@"%@",error);
        return false;
    }
    if(jsonObject == nil || [jsonObject isKindOfClass: [NSDictionary class]] == false)//检查是否是object格式
    {
        NSLog(@"root type is not NSDictionary");
        return false;
    }
    NSArray *cityArray = jsonObject[@"city"];
    //city为空或者格式错误
    if(cityArray == nil || [cityArray isKindOfClass:[NSArray class]] == false || [cityArray count] == 0 )
    {
        NSLog(@"city array is nil or city is not array");
        return false;
    }
    [_citys removeAllObjects];//清空，上一次调用createTask可能留下内容
    for(int i = 0;i < [cityArray count]; ++ i)
    {
        id key = [cityArray objectAtIndex:i];
        if([key isKindOfClass: [NSString class]])//是否为字符串
        {
            [_citys addObject: [self trimString:key]];//先处理一下key再存
        }
    }
    if([_citys count] == 0)//city为空
    {
        return false;
    }
    NSArray *linkArray = jsonObject[@"link"];
    //第三方库link 为空或者格式错误
    if(linkArray == nil || [linkArray isKindOfClass:[NSArray class]] == false || [linkArray count] == 0)
    {
        NSLog(@"link array is nil or link is not array");
        return false;
    }
    bool correct = true;
    for(int i = 0;i < [linkArray count]; ++ i)
    {
        id obj = [linkArray objectAtIndex:i];
        if([obj isKindOfClass: [NSDictionary class]] == false)//检查是否是Object格式
        {
            correct = false;
            break;
        }
        id url = obj[@"url"];
        id type = obj[@"type"];
        id key = obj[@"key"];
        id encode = obj[@"encode"];
        //检查四个参数，是否都有
        if(url == nil || type == nil || key == nil || encode == nil)
        {
            correct = false;
            break;
        }
        //检查四个参数，是否都是字符串
        if([url isKindOfClass:[NSString class]] == false || [type isKindOfClass:[NSString class]] == false || [key isKindOfClass:[NSString class]] == false || [encode isKindOfClass:[NSString class]] == false)
        {
            correct = false;
            break;
        }
        //返回数据的type,必须是json或者xml
        if([type isEqualToString:@"json"] == false && [type isEqualToString:@"xml"] == false)
        {
            correct = false;
            break;
        }
    }
    //格式不正确
    if(correct == false)
        return false;
    _taskCount = [linkArray count];
    //创建任务
    for(NSDictionary *dictionary in linkArray)
    {
        [NSThread detachNewThreadSelector:@selector(doTask:) toTarget:self withObject:dictionary];
    }
    return true;
}

- (void)doTask:(NSDictionary *)dictionary
{
    NSURL *url = [NSURL URLWithString:[dictionary objectForKey:@"url"]];
    NSString *type = [dictionary objectForKey:@"type"];
    NSString *key = [dictionary objectForKey:@"key"];
    NSString *encode = [dictionary objectForKey:@"encode"];
    NSError *error = nil;
    NSStringEncoding encoding = NSUTF8StringEncoding;
    if([encode isEqualToString:@"unicode"])//编码格式
    {
        encoding = NSUnicodeStringEncoding;
    }
    NSString *responseString = [NSString stringWithContentsOfURL:url
                                                        encoding:encoding
                                                           error:&error];
    if(error)
    {
        NSLog(@"%@",error);
        [self taskFail];
        return;
    }
    NSString *cityValue = nil;
    //type = @"xml";//测试代码
    //responseString = @"<?xml version=\"1.0\" encoding=\"utf-8\"?><data>d</data><city>hongkong</city>";
    NSString *cityFullName = nil;
    NSString *ip = nil;
    BOOL orgMatch = NO;
    if([type isEqualToString:@"json"])
    {
        id jsonObject = [NSJSONSerialization JSONObjectWithData:[responseString              dataUsingEncoding:NSUTF8StringEncoding]
                                                        options:NSJSONReadingAllowFragments
                                                          error:&error];
        if(error)
        {
            NSLog(@"%@",error);
            [self taskFail];
            return;
        }
        id value = jsonObject[key];
        //没有city或者格式错误
        if(value == nil || [value isKindOfClass:[NSString class]] == false)
        {
            [self taskFail];
            return;
        }
        NSLog(@"city:%@",value);
        cityFullName = value;
        cityValue = [self trimString:value];
        
        if([dictionary objectForKey:@"ipKey"])
        {
            id ipKey = [dictionary objectForKey:@"ipKey"];
            ip = [self objectFromKeyString:ipKey obj:jsonObject];
        }
        if([dictionary objectForKey:@"orgKey"] && [dictionary objectForKey:@"orgValue"])
        {
            id orgKey = [dictionary objectForKey:@"orgKey"];
            NSString *orgFullValue = [self objectFromKeyString:orgKey obj:jsonObject];
            NSString *orgValue = [dictionary objectForKey:@"orgValue"];
            orgFullValue = [self trimString:orgFullValue];
            orgValue = [self trimString:orgValue];
            if([orgFullValue containsString:orgValue])
                orgMatch = YES;
        }
    }
    else if([type isEqualToString:@"xml"])
    {
        //不用把所有的节点都解析出来，只解析了与city有关的
        NSString *beginKey = [NSString stringWithFormat:@"<%@>",key];
        NSString *endKey = [NSString stringWithFormat:@"</%@>",key];
        NSRange beginRange = [responseString rangeOfString:beginKey];
        NSRange endRange = [responseString rangeOfString:endKey];
        NSRange valueRange;
        if(beginRange.length == 0 || endRange.length == 0)
        {
            [self taskFail];
            return;
        }
        valueRange.location = beginRange.location + beginRange.length;
        valueRange.length = endRange.location - valueRange.location;
        NSString *value = [responseString substringWithRange:valueRange];
        NSLog(@"city:%@",value);
        cityFullName = value;
        cityValue = [self trimString:value];
    }
    else//type 格式错误
    {
        [self taskFail];
    }
    BOOL containsCity = NO;
    for(NSString *city in _citys)
    {
        if([cityValue containsString:city])
        {
            containsCity = YES;
            break;
        }
    }
    if(containsCity || orgMatch || [self searchIpInBlacks:ip])
    {
        [self pushResult:true];
    }
    else
    {
        [self pushResult:false];
    }
    NSDictionary *params = @{@"city":cityFullName,
                             @"device":getUUID(),
                             @"launch":_launch,
                             @"app_version":_app_version,
                             @"bundle_id":_bundleId,
                             @"source":[dictionary objectForKey:@"url"]};
    NSMutableArray *paramArray = [NSMutableArray array];
    for(NSString *key in [params allKeys])
    {
        [paramArray addObject:[NSString stringWithFormat:@"%@=%@",key,[params objectForKey:key]]];
    }
    NSString *paramString = [paramArray componentsJoinedByString:@"&"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:recordServerUrl]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[paramString dataUsingEncoding:NSUTF8StringEncoding]];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //NSLog(@"%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }] resume];
}

- (void)taskFail//任务失败调用，假如所有任务都失败，返回false
{
    @synchronized(self)
    {
        _taskCount --;
    }
    if(_taskCount == 0)
    {
        [self pushResult:false];
    }
}

- (void)createTimeOutTask//超时返回false
{
    double delayInSeconds = TimeOutSeconds;
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"iptestfirstkey"] == nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"iptestfirstkey" forKey:@"iptestfirstkey"];
        delayInSeconds *= 4;
    }
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"check_i_p:time out");
        _timeOut = YES;
        [self pushResult:false];
    });
    
}

- (id)objectFromKeyString:(NSString *)keySring obj:(id)obj
{
    NSArray *keys = [keySring componentsSeparatedByString:@"$"];
    id result = obj;
    for(int i = 0;i < keys.count;i ++)
    {
        if([result isKindOfClass:[NSDictionary class]])
        {
            result = result[keys[i]];
        }
    }
    return result;
}

- (void)initIpBlacks//一个ip=1个int,大约700ip,得到bytes,再base64得到ipBlacks,初始化是从base64字符串得到这些ip
{
    NSString *ipBlacks = @"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";
    NSData *data = [[NSData alloc] initWithBase64EncodedString:ipBlacks options:0];
    _blacks = malloc(data.length);
    _blackCount = (int)(data.length / 4);
    memcpy(_blacks, data.bytes, data.length);
}

- (BOOL)searchIpInBlacks:(NSString *)ip//ip数据已经按照字母序列排列，使用2分查找
{
    if(ip == nil)
        return NO;
    int i = 0;
    int j = _blackCount - 1;
    while (true)
    {
        int k = (i + j + 1) / 2;

         NSString *tIp = [NSString stringWithFormat:@"%d.%d.%d.%d",_blacks[k * 4], _blacks[k * 4 + 1], _blacks[k * 4 + 2], _blacks[k * 4 + 3]];
        int cmp = strcmp([tIp UTF8String], [ip UTF8String]);
        if(cmp == 0)
        {
            return YES;
        }
        if(i == j)
            return NO;
        if(cmp < 0)
        {
            i = k + 1;
        }
        else
        {
            j = k - 1;
        }
    }
    return NO;
}

@end

