//
//  AFNetAPIClient.m
//  Networking
//
//  Created by 苏沫离 on 2020/6/2.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "AFNetAPIClient.h"

@implementation AFNetAPIClient

/** 创建一个单例类
 */
+(AFNetAPIClient*)sharedClient{
    static AFNetAPIClient* _sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
     
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        //[config setHTTPAdditionalHeaders:@{@"User-Agent" : @"DZM iOS 1.0.0"}];

        NSURLCache* cache = [[NSURLCache alloc]initWithMemoryCapacity:10*1024*1024 diskCapacity:50*1024*1024 diskPath:nil];
        [config setURLCache:cache];


        NSURL *baseURL = [NSURL URLWithString:DOMAINBASE];
        _sharedClient = [[self alloc]initWithBaseURL:baseURL sessionConfiguration:config];
        _sharedClient.operationQueue.maxConcurrentOperationCount = 1;// 设置允许同时最大并发数量，过大容易出问题

        // 设置请求序列化器
        [_sharedClient.requestSerializer willChangeValueForKey:@"timeoutInterval"];
        _sharedClient.requestSerializer.timeoutInterval = PostTimeOutInterval;
        [_sharedClient.requestSerializer didChangeValueForKey:@"timeoutInterval"];


        _sharedClient.completionQueue = dispatch_queue_create("com.demo.completionQueue", DISPATCH_QUEUE_CONCURRENT);
        _sharedClient.startRequestQueue = [[NSOperationQueue alloc] init];
        _sharedClient.startRequestQueue.maxConcurrentOperationCount = 9;//最大可以同时开启的请求数

        // 设置响应序列化器，解析Json对象
        AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
        responseSerializer.removesKeysWithNullValues = YES; // 清除返回数据的 NSNull
        responseSerializer.readingOptions = NSJSONReadingMutableContainers;
        responseSerializer.acceptableContentTypes = [NSSet setWithObjects:  @"application/x-javascript", @"application/json", @"text/json", @"text/javascript", @"text/html", @"text/plain",nil]; // 设置接受数据的格式
        _sharedClient.responseSerializer = responseSerializer;

        // 设置安全策略
        _sharedClient.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];;
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    });
    return _sharedClient;
    
}

- (void)setSecurityPolicyClick{
    // 先导入证书 证书由服务端生成，具体由服务端人员操作
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"client" ofType:@"cer"];//证书的路径
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    // 设置安全策略
    self.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    // 如果是需要验证自建证书，需要设置为YES
    self.securityPolicy.allowInvalidCertificates = YES;
    //validatesDomainName 是否需要验证域名，默认为YES;
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    self.securityPolicy.validatesDomainName = NO;
    self.securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
}



/** get 请求
 * url 请求地址
 *
 * responseObject 请求结果
 * error 若请求失败则返回错误，否则返回nil
 */
-(NSURLSessionDataTask *)requestForGetUrl:(NSString*)url success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure{
    //没有网络，返回无网络
    if([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable){
        NSError *error = [NSError errorWithDomain:@"没有网络" code:700 userInfo:nil];
        failure(error);
        return nil;
    }
    
    [self.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    self.requestSerializer.timeoutInterval = PostTimeOutInterval;
    [self.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    if ([url containsString:URL_CityList]){
        self.requestSerializer.allowsCellularAccess = NO;
        [self.requestSerializer willChangeValueForKey:@"cachePolicy"];
        self.requestSerializer.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
        [self.requestSerializer didChangeValueForKey:@"cachePolicy"];
    }else{
        self.requestSerializer.allowsCellularAccess = YES;
        [self.requestSerializer willChangeValueForKey:@"cachePolicy"];
        self.requestSerializer.cachePolicy = NSURLRequestUseProtocolCachePolicy;
        [self.requestSerializer didChangeValueForKey:@"cachePolicy"];
    }

    NSURLSessionDataTask* task = [self GET:url parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self cacheCookie:task.response];
        [self logSessionDataTask:task ResponseObject:responseObject];

        if (!responseObject || (![responseObject isKindOfClass:[NSDictionary class]] && ![responseObject isKindOfClass:[NSArray class]])){ // 若解析数据格式异常，返回错误
            NSError *error = [NSError errorWithDomain:@"数据异常" code:100 userInfo:nil];
            failure(error);
        }else{
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
    return task;
}

/** post 请求
 * url 请求地址
 * parameters 请求参数 为nil
 *
 * cacheType 缓存类型
 *
 * isCacheData 返回的数据是否是本地缓存数据
 * responseObject 请求结果
 * error 若请求失败则返回错误，否则返回nil
 */
-(NSURLSessionDataTask *)requestForPostUrl:(NSString*)url Parameters:(NSDictionary *)parameters success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure{
    
    //没有网络，返回无网络
    if([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable){
        NSError *error = [NSError errorWithDomain:@"没有网络" code:700 userInfo:nil];
        failure(error);
        return nil;
    }
    
    [self.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    self.requestSerializer.timeoutInterval = PostTimeOutInterval;
    [self.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    NSURLSessionDataTask* task = [self POST:url parameters:parameters headers:nil progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [self cacheCookie:task.response];
        [self logSessionDataTask:task ResponseObject:responseObject];
        if (!responseObject || (![responseObject isKindOfClass:[NSDictionary class]] && ![responseObject isKindOfClass:[NSArray class]])){ // 若解析数据格式异常，返回错误
            NSError *error = [NSError errorWithDomain:@"数据异常" code:100 userInfo:nil];
            failure(error);
        }else{
            success(responseObject);
        }
          
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
    return task;
}

- (void)cacheCookie:(NSURLResponse *)response{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSString *cookie = httpResponse.allHeaderFields[@"Set-Cookie"];
    
    [[NSUserDefaults standardUserDefaults] setObject:cookie forKey:@"cookie"];
    [[NSUserDefaults standardUserDefaults] synchronize];    
}

- (void)logSessionDataTask:(NSURLSessionDataTask *)task ResponseObject:(id  _Nullable) responseObject{
    printf("\n \n \n \n ******** 打印 SessionDataTask 开始******** \n");

    if ([responseObject isKindOfClass:[NSDictionary class]]){
        if ([responseObject[@"code"] intValue] != 0){
            [[NSOperationQueue mainQueue]addOperationWithBlock:^{
//                [UIApplication.sharedApplication.keyWindow makeToast:responseObject[@"message"] duration:5 position:CSToastPositionCenter];
            }];
        }
    }
    
    NSURLRequest *request = task.currentRequest;
    
    NSLog(@"\n --------- currentRequest --------- \n URL:%@ \n cachePolicy:%lu \n timeoutInterval:%f \n mainDocumentURL : %@ \n networkServiceType : %lu \n HTTPMethod : %@ \n allowsCellularAccess: %d \n HTTPShouldHandleCookies : %d \n HTTPShouldUsePipelining:%d \n allHTTPHeaderFields: %@ \n --------- response --------- \n response : %@ \n --------- responseObject --------- \n responseObject : %@",request.URL,(unsigned long)request.cachePolicy,request.timeoutInterval,request.mainDocumentURL,request.networkServiceType,request.HTTPMethod,request.allowsCellularAccess,request.HTTPShouldHandleCookies,request.HTTPShouldUsePipelining,request.allHTTPHeaderFields,task.response,[self unicodeFilterFromDic:responseObject]);
    printf("\n ******** 打印 SessionDataTask 结束******** \n \n \n");
}

- (NSString *)unicodeFilterFromDic:(NSDictionary *)responseObject{
    if (responseObject == nil){
        return @"";
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonStr;
}

@end
