#import "AFHTTPSessionManager.h"

#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"

#import <Availability.h>
#import <TargetConditionals.h>
#import <Security/Security.h>

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#elif TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#endif

@interface AFHTTPSessionManager ()
@property (readwrite, nonatomic, strong) NSURL *baseURL;
@end

@implementation AFHTTPSessionManager
@dynamic responseSerializer;

+ (instancetype)manager {
    return [[[self class] alloc] initWithBaseURL:nil];
}

- (instancetype)init {
    return [self initWithBaseURL:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    return [self initWithBaseURL:url sessionConfiguration:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    return [self initWithBaseURL:nil sessionConfiguration:configuration];
}

- (instancetype)initWithBaseURL:(NSURL *)url sessionConfiguration:(NSURLSessionConfiguration *)configuration{
    //调用父类方法获取一个 AFURLSessionManager
    self = [super initWithSessionConfiguration:configuration];
    if (!self) {
        return nil;
    }

    //对传过来的BaseUrl进行处理，如果有值且最后不包含/，url加上"/"
    if ([[url path] length] > 0 && ![[url absoluteString] hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    // baseURL 赋值
    self.baseURL = url;

    //构建了 HTTPS 请求的请求序列化器 与 响应Json格式的 响应序列化器
    self.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.responseSerializer = [AFJSONResponseSerializer serializer];
    return self;
}

#pragma mark -

- (void)setRequestSerializer:(AFHTTPRequestSerializer <AFURLRequestSerialization> *)requestSerializer {
    NSParameterAssert(requestSerializer);
    _requestSerializer = requestSerializer;
}

- (void)setResponseSerializer:(AFHTTPResponseSerializer <AFURLResponseSerialization> *)responseSerializer {
    NSParameterAssert(responseSerializer);
    [super setResponseSerializer:responseSerializer];
}

@dynamic securityPolicy;

- (void)setSecurityPolicy:(AFSecurityPolicy *)securityPolicy {
    //不是 Https 请求，不需要证书验证
    if (securityPolicy.SSLPinningMode != AFSSLPinningModeNone &&
        ![self.baseURL.scheme isEqualToString:@"https"]) {
        NSString *pinningMode = @"Unknown Pinning Mode";
        switch (securityPolicy.SSLPinningMode) {
            case AFSSLPinningModeNone:        pinningMode = @"AFSSLPinningModeNone"; break;
            case AFSSLPinningModeCertificate: pinningMode = @"AFSSLPinningModeCertificate"; break;
            case AFSSLPinningModePublicKey:   pinningMode = @"AFSSLPinningModePublicKey"; break;
        }
        NSString *reason = [NSString stringWithFormat:@"A security policy configured with `%@` can only be applied on a manager with a secure base URL (i.e. https)", pinningMode];
        @throw [NSException exceptionWithName:@"Invalid Security Policy" reason:reason userInfo:nil];
    }
    [super setSecurityPolicy:securityPolicy];
}

#pragma mark -

/** 创建 GET 请求并运行 NSURLSessionDataTask
 * @param URLString 请求地址
 * @param parameters 请求参数
 * @param headers 附加到默认头的某些信息，仅限此请求
 * @param downloadProgress 下载进度监控，注意，此块是在会话队列上调用的，而不是在主队列上。
 * @param success 任务成功完成时的回调
 * @param failure 当任务未成功完成、或成功完成但解析响应数据时遇到错误时的回调。
 */
- (NSURLSessionDataTask *)GET:(NSString *)URLString
                   parameters:(nullable id)parameters
                      headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                     progress:(nullable void (^)(NSProgress * _Nonnull))downloadProgress
                      success:(nullable void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                      failure:(nullable void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"GET"
                                                        URLString:URLString
                                                       parameters:parameters
                                                          headers:headers
                                                   uploadProgress:nil
                                                 downloadProgress:downloadProgress
                                                          success:success
                                                          failure:failure];
    [dataTask resume];//开始网络请求：刚创建出来的task默认是挂起状态的，需要调用该方法来启动任务
    return dataTask;
}

/** 创建 HEAD 请求并运行 NSURLSessionDataTask
 * @note HEAD 请求 : 向服务器索要与GET请求相一致的响应，只不过响应体将不会被返回；在不需要传输整个响应内容的情况下，仅获取包含在响应消息头中的元信息。
 *                  该方法常用于测试超链接的有效性，是否可以访问，以及最近是否更新。
*/
- (NSURLSessionDataTask *)HEAD:(NSString *)URLString
                    parameters:(nullable id)parameters
                       headers:(nullable NSDictionary<NSString *,NSString *> *)headers
                       success:(nullable void (^)(NSURLSessionDataTask * _Nonnull))success
                       failure:(nullable void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"HEAD" URLString:URLString parameters:parameters headers:headers uploadProgress:nil downloadProgress:nil success:^(NSURLSessionDataTask *task, __unused id responseObject) {
        if (success) {
            success(task);
        }
    } failure:failure];
    [dataTask resume];
    return dataTask;
}


/** 创建 POST 请求并运行 NSURLSessionDataTask
 * @param uploadProgress 上传进度监控。注意，此块是在会话队列上调用的，而不是在主队列上。
 * @note POST 请求 : 向指定资源提交数据，例如提交表单或者上传文件；数据被包含在请求体中；
 *       POST请求可能会导致新的资源的建立和/或已有资源的修改。
 */
- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable id)parameters
                                headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                                success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"POST" URLString:URLString parameters:parameters headers:headers uploadProgress:uploadProgress downloadProgress:nil success:success failure:failure];
    [dataTask resume];
    return dataTask;
}

/** 创建 POST 请求上传文件，执行上传任务 NSURLSessionUploadTask
 *  @discussion 该方法做了两件事：
 *   <1>、创建并配置 NSMutableURLRequest 实例
 *   <2>、通过 NSMutableURLRequest 实例创建一个上传任务 NSURLSessionUploadTask
 *
 * @param block 接受单个 block 参数并将数据附加到 HTTP 主体；block参数遵守 AFMultipartFormData 协议
 */
- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(nullable id)parameters
                       headers:(nullable NSDictionary<NSString *,NSString *> *)headers
     constructingBodyWithBlock:(nullable void (^)(id<AFMultipartFormData> _Nonnull))block
                      progress:(nullable void (^)(NSProgress * _Nonnull))uploadProgress
                       success:(nullable void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure{
    
    /********* 1、创建并配置 NSMutableURLRequest  *********/
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:&serializationError];
    for (NSString *headerField in headers.keyEnumerator) {//设置请求头信息
        [request setValue:headers[headerField] forHTTPHeaderField:headerField];
    }
    if (serializationError) {
        if (failure) {
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
        }
        return nil;
    }
    
    /********* 2、通过 NSMutableURLRequest 实例创建一个上传任务 NSURLSessionUploadTask   *********/
    __block NSURLSessionDataTask *task = [self uploadTaskWithStreamedRequest:request progress:uploadProgress completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(task, error);
            }
        } else {
            if (success) {
                success(task, responseObject);
            }
        }
    }];
    [task resume];
    return task;
}

/** 创建 PUT 请求并运行 NSURLSessionDataTask
 * @note PUT请求: 向指定资源位置上传其最新内容;
*/
- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(nullable id)parameters
                      headers:(nullable NSDictionary<NSString *,NSString *> *)headers
                      success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"PUT" URLString:URLString parameters:parameters headers:headers uploadProgress:nil downloadProgress:nil success:success failure:failure];
    [dataTask resume];
    return dataTask;
}

/** 创建 PATCH 请求并运行 NSURLSessionDataTask
 * @note PATCH请求 : 用来将局部修改应用于某一资源，添加于规范RFC5789 ;
 */
- (NSURLSessionDataTask *)PATCH:(NSString *)URLString
                     parameters:(nullable id)parameters
                        headers:(nullable NSDictionary<NSString *,NSString *> *)headers
                        success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                        failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"PATCH" URLString:URLString parameters:parameters headers:headers uploadProgress:nil downloadProgress:nil success:success failure:failure];
    [dataTask resume];
    return dataTask;
}

/** 创建 DELETE 请求并运行 NSURLSessionDataTask
 * @note DELETE 请求：服务器删除 URI 所标识的资源
 */
- (NSURLSessionDataTask *)DELETE:(NSString *)URLString
                      parameters:(nullable id)parameters
                         headers:(nullable NSDictionary<NSString *,NSString *> *)headers
                         success:(nullable void (^)(NSURLSessionDataTask *task, id responseObject))success
                         failure:(nullable void (^)(NSURLSessionDataTask *task, NSError *error))failure{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"DELETE" URLString:URLString parameters:parameters headers:headers uploadProgress:nil downloadProgress:nil success:success failure:failure];
    [dataTask resume];
    return dataTask;
}



/** 创建一个自定义的 HTTPMethod 请求并运行 NSURLSessionDataTask
 * @discussion 该方法做了两件事：
 *   <1>、创建并配置 NSMutableURLRequest 实例
 *   <2>、通过 NSMutableURLRequest 实例创建一个任务 NSURLSessionDataTask
 *
 * @param method 用于创建请求的HTTPMethod字符串
 * @param URLString 请求地址
 * @param parameters 请求参数
 * @param headers 附加到默认头的某些信息，仅限此请求
 * @param uploadProgress 上传进度监控。注意，此块是在会话队列上调用的，而不是在主队列上。
 * @param downloadProgress 下载进度监控，注意，此块是在会话队列上调用的，而不是在主队列上。
 * @param success 任务成功完成时的回调
 * @param failure 当任务未成功完成、或成功完成但解析响应数据时遇到错误时的回调。
 * @see -dataTaskWithRequest:uploadProgress:downloadProgress:completionHandler:
 */
- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method URLString:(NSString *)URLString parameters:(nullable id)parameters headers:(nullable NSDictionary <NSString *, NSString *> *)headers uploadProgress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgress success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure{
    
    NSError *serializationError = nil;
    /********* 1、创建并配置 NSMutableURLRequest  *********/
    //把参数，还有各种东西转化为一个request
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:&serializationError];
    for (NSString *headerField in headers.keyEnumerator) {//设置请求头信息
        [request setValue:headers[headerField] forHTTPHeaderField:headerField];
    }
    if (serializationError) {
        if (failure) {//如果解析错误，直接返回
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
        }
        return nil;
    }

    /********* 2、通过 NSMutableURLRequest 实例创建一个任务 NSURLSessionDataTask   *********/
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest:request uploadProgress:uploadProgress downloadProgress:downloadProgress
                       completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(dataTask, error);
            }
        } else {
            if (success) {
                success(dataTask, responseObject);
            }
        }
    }];
    return dataTask;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, baseURL: %@, session: %@, operationQueue: %@>", NSStringFromClass([self class]), self, [self.baseURL absoluteString], self.session, self.operationQueue];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

//重写 编码/解码 方法
- (instancetype)initWithCoder:(NSCoder *)decoder {
    NSURL *baseURL = [decoder decodeObjectOfClass:[NSURL class] forKey:NSStringFromSelector(@selector(baseURL))];
    NSURLSessionConfiguration *configuration = [decoder decodeObjectOfClass:[NSURLSessionConfiguration class] forKey:@"sessionConfiguration"];
    if (!configuration) {
        NSString *configurationIdentifier = [decoder decodeObjectOfClass:[NSString class] forKey:@"identifier"];
        if (configurationIdentifier) {
            configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:configurationIdentifier];
        }
    }
    self = [self initWithBaseURL:baseURL sessionConfiguration:configuration];
    if (!self) {
        return nil;
    }
    self.requestSerializer = [decoder decodeObjectOfClass:[AFHTTPRequestSerializer class] forKey:NSStringFromSelector(@selector(requestSerializer))];
    self.responseSerializer = [decoder decodeObjectOfClass:[AFHTTPResponseSerializer class] forKey:NSStringFromSelector(@selector(responseSerializer))];
    AFSecurityPolicy *decodedPolicy = [decoder decodeObjectOfClass:[AFSecurityPolicy class] forKey:NSStringFromSelector(@selector(securityPolicy))];
    if (decodedPolicy) {
        self.securityPolicy = decodedPolicy;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.baseURL forKey:NSStringFromSelector(@selector(baseURL))];
    if ([self.session.configuration conformsToProtocol:@protocol(NSCoding)]) {
        [coder encodeObject:self.session.configuration forKey:@"sessionConfiguration"];
    } else {
        [coder encodeObject:self.session.configuration.identifier forKey:@"identifier"];
    }
    [coder encodeObject:self.requestSerializer forKey:NSStringFromSelector(@selector(requestSerializer))];
    [coder encodeObject:self.responseSerializer forKey:NSStringFromSelector(@selector(responseSerializer))];
    [coder encodeObject:self.securityPolicy forKey:NSStringFromSelector(@selector(securityPolicy))];
}

#pragma mark - NSCopying
//重写 -copy 方法
- (instancetype)copyWithZone:(NSZone *)zone {
    AFHTTPSessionManager *HTTPClient = [[[self class] allocWithZone:zone] initWithBaseURL:self.baseURL sessionConfiguration:self.session.configuration];
    HTTPClient.requestSerializer = [self.requestSerializer copyWithZone:zone];
    HTTPClient.responseSerializer = [self.responseSerializer copyWithZone:zone];
    HTTPClient.securityPolicy = [self.securityPolicy copyWithZone:zone];
    return HTTPClient;
}

@end
