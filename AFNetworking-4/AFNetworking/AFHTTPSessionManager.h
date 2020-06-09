
#import <Foundation/Foundation.h>
#if !TARGET_OS_WATCH
#import <SystemConfiguration/SystemConfiguration.h>
#endif
#import <TargetConditionals.h>

#import "AFURLSessionManager.h"

/** AFHTTPSessionManager 是对 AFURLSessionManager 的进一步封装，通过相对路径 baseURL 更方便的发送 GET/POST 等 HTTP 请求。
 * @note 最好使用单例，在单例对象上共享身份验证和其他配置。
 * Serialization ：客户端创建 HTTP 的请求 包含默认头和 requestSerializer 编码的参数；
 *                 客户端接收到服务器的响应数据会被 responseserializer 自动验证和序列化；
 * 如果 baseURL 为 nil，可以使用 NSURL 的 +URLWithString:relativeToURL: 方法构造一个有效的 NSURL 对象；
 * 下面是一些 baseURL 和相对路径如何相互作用的例子:
 *     NSURL *baseURL = [NSURL URLWithString:@"http://example.com/v1/"];
 *     [NSURL URLWithString:@"foo" relativeToURL:baseURL];                  // http://example.com/v1/foo
 *     [NSURL URLWithString:@"foo?bar=baz" relativeToURL:baseURL];          // http://example.com/v1/foo?bar=baz
 *     [NSURL URLWithString:@"/foo" relativeToURL:baseURL];                 // http://example.com/foo
 *     [NSURL URLWithString:@"foo/" relativeToURL:baseURL];                 // http://example.com/v1/foo
 *     [NSURL URLWithString:@"/foo/" relativeToURL:baseURL];                // http://example.com/foo/
 *     [NSURL URLWithString:@"http://example2.com/" relativeToURL:baseURL]; // http://example2.com/
 *
 *
 * @warning 后台会话的 Managers 在使用期间不能被释放；这可以通过单例来实现。
 */
NS_ASSUME_NONNULL_BEGIN

@interface AFHTTPSessionManager : AFURLSessionManager <NSSecureCoding, NSCopying>

/** 通过相对路径 baseURL 更方便的构造一个有效的 NSURL 对象 */
@property (readonly, nonatomic, strong, nullable) NSURL *baseURL;

/** 工具类：用于将请求参数序列化，不能为 nil。
 * 默认配置的实例，它会将 GET 、HEAD 和 DELETE 请求的查询字符串参数序列化，或者以其他url形式对HTTP消息体进行编码。
 */
@property (nonatomic, strong) AFHTTPRequestSerializer <AFURLRequestSerialization> * requestSerializer;

/** 工具类：将从服务器接收到的 GET/POST 请求的响应数据序列化，不能为 nil。
 */
@property (nonatomic, strong) AFHTTPResponseSerializer <AFURLResponseSerialization> * responseSerializer;

///-------------------------------
/// @name Managing 安全策略
///-------------------------------

/** 验证 HTTPS 请求的证书是否有效，如果 APP 中有一些敏感信息或者涉及交易信息，一定要使用 HTTPS 来保证交易或者用户信息的安全。
 * AFSSLPinningModeNone  不使用固定证书（本地）验证服务器。直接从客户端系统中的受信任颁发机构 CA 列表中去验证
 * AFSSLPinningModePublicKey 对服务器返回的证书中的PublicKey进行验证，通过则通过，否则不通过
 * AFSSLPinningModeCertificate 对服务器返回的证书同本地证书全部进行校验，通过则通过，否则不通过
  */
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

///---------------------
/// @name 初始化
///---------------------

/** 创建并返回一个 AFHTTPSessionManager 对象
 */
+ (instancetype)manager;

/** 使用指定的 BaseURL 创建一个 AFHTTPSessionManager 对象
 */
- (instancetype)initWithBaseURL:(nullable NSURL *)url;

/** 使用指定的 BaseURL 创建一个 AFHTTPSessionManager 对象
 * @param configuration 会话配置
 */
- (instancetype)initWithBaseURL:(nullable NSURL *)url
           sessionConfiguration:(nullable NSURLSessionConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

///---------------------------
/// @name 发送 HTTP 请求
///---------------------------

/** 创建 GET 请求并运行 NSURLSessionDataTask
 * @param URLString 请求地址
 * @param parameters 请求参数
 * @param headers 附加到默认头的某些信息，仅限此请求
 * @param downloadProgress 下载进度监控，注意，此块是在会话队列上调用的，而不是在主队列上。
 * @param success 任务成功完成时的回调
 * @param failure 当任务未成功完成、或成功完成但解析响应数据时遇到错误时的回调。
 */
- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                            parameters:(nullable id)parameters
                               headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                              progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                               success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                               failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

/** 创建 HEAD 请求并运行 NSURLSessionDataTask
 * @note HEAD 请求 : 向服务器索要与GET请求相一致的响应，只不过响应体将不会被返回；在不需要传输整个响应内容的情况下，仅获取包含在响应消息头中的元信息。
 *                  该方法常用于测试超链接的有效性，是否可以访问，以及最近是否更新。
*/
- (nullable NSURLSessionDataTask *)HEAD:(NSString *)URLString
                             parameters:(nullable id)parameters
                                headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                                success:(nullable void (^)(NSURLSessionDataTask *task))success
                                failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

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
                                failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

/** 创建 NSMutableURLRequest 的 POST 请求并运行 NSURLSessionUploadTask
 * @param block 接受单个 block 参数并将数据附加到 HTTP 主体；block参数遵守 AFMultipartFormData 协议
 */
- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable id)parameters
                                headers:(nullable NSDictionary <NSString *, NSString *> *)headers
              constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                                success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

/** 创建 PUT 请求并运行 NSURLSessionDataTask
 * @note PUT请求: 向指定资源位置上传其最新内容;
 * @see -dataTaskWithRequest:completionHandler:
 */
- (nullable NSURLSessionDataTask *)PUT:(NSString *)URLString
                            parameters:(nullable id)parameters
                               headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                               success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                               failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

/** 创建 PATCH 请求并运行 NSURLSessionDataTask
 * @note PATCH请求 : 用来将局部修改应用于某一资源，添加于规范RFC5789 ;
 * @see -dataTaskWithRequest:completionHandler:
*/
- (nullable NSURLSessionDataTask *)PATCH:(NSString *)URLString
                              parameters:(nullable id)parameters
                                 headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                                 success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                 failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

/** 创建 DELETE 请求并运行 NSURLSessionDataTask
 * @note DELETE 请求：服务器删除 URI 所标识的资源
 * @see -dataTaskWithRequest:completionHandler:
 */
- (nullable NSURLSessionDataTask *)DELETE:(NSString *)URLString
                               parameters:(nullable id)parameters
                                  headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                                  success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                  failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

/** 创建一个自定义的 HTTPMethod 请求并运行 NSURLSessionDataTask
 * @param method 用于创建请求的HTTPMethod字符串
 * @see -dataTaskWithRequest:uploadProgress:downloadProgress:completionHandler:
 */
- (nullable NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                                URLString:(NSString *)URLString
                                               parameters:(nullable id)parameters
                                                  headers:(nullable NSDictionary <NSString *, NSString *> *)headers
                                           uploadProgress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                                         downloadProgress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                                                  success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                                  failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
