// AFURLRequestSerialization.h
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#elif TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/** 根据 RFC3986 规范进行编码后的字符串
 *
 * @Abstract 由于 URL 的字符串中某些字符可能引起歧义，需要对 URL 编码：
 *          URL 编码格式采用 ASCII 码，而不是 Unicode，这也就是说不能在 URL 中包含任何非ASCII字符，如中文 ；
 *          URL 编码原则就是使用安全的字符（没有特殊用途或者特殊意义的可打印字符）去表示那些不安全的字符。
 *
 * @need 哪些字符需要编码? RFC3986文档规定，URL 中只允许包含英文字母（a-zA-Z）、数字（0-9）、-_.~ 4个特殊字符以及下述保留字符：
 *  <ul>
 *     <li> 普通的分隔符 ":", "#", "[", "]", "@", "?", "/"
 *     <li> 子分隔符: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
 *  </ul>
 *
 * @param string 待编码请求参数，'?'和'/'可以不用编码，其他的都要进行编码。
 */
FOUNDATION_EXPORT NSString * AFPercentEscapedStringFromString(NSString *string);

/** 将 parameters 中的参数附加到 URL 末尾并编码
 * @case 如 @{@"name":@"zhangsan",@"age":20} 附加为 name=zhangsan&age=20
 */
FOUNDATION_EXPORT NSString * AFQueryStringFromParameters(NSDictionary *parameters);



/** AFURLRequestSerialization 协议用来为指定的 HTTP 请求编码参数。请求序列化器将参数编码为查询字符串、HTTP正文，并根据需要设置 HTTP header fields ！
 * 例如，JSON 请求序列化器可以将请求的 HTTP body设置为JSON表示，并将HTTP头字段 Content-Type 值设置为 application/ JSON
 */
@protocol AFURLRequestSerialization <NSObject, NSSecureCoding, NSCopying>

/** 将参数 parameters 编码到 NSURLRequest ，并返回副本
 * @param request 最初的 request 请求
 * @param parameters 待编码的参数
 * @param error 编码时遇到的错误
 */
- (nullable NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(nullable id)parameters
                                        error:(NSError * _Nullable __autoreleasing *)error NS_SWIFT_NOTHROW;

/** NS_SWIFT_NOTHROW 在swift中没有错误抛出
 * NS_SWIFT_UNAVAILABLE 在swift中无效
 * NS_NOESCAPE swift中有逃逸概念，默认闭包是noescap
*/

@end

#pragma mark -


///枚举：请求参数序列化类型
typedef NS_ENUM(NSUInteger, AFHTTPRequestQueryStringSerializationStyle) {
    AFHTTPRequestQueryStringDefaultStyle = 0,
};

@protocol AFMultipartFormData;

/** AFHTTPRequestSerializer 处理所有的HTTP请求的响应，提供响应报文可接受HTTP的状态码，验证响应状态码和有效的 Content-Type 。
 * 主要实现了根据不同情况和参数初始化NSURLRequest对象的功能
 */
@interface AFHTTPRequestSerializer : NSObject <AFURLRequestSerialization>

/** 字符串编码格式，默认 NSUTF8StringEncoding
 */
@property (nonatomic, assign) NSStringEncoding stringEncoding;

/** 创建的请求是否可以使用该设备的蜂窝网络(如果存在)，默认 YES 可以使用
 * @see NSMutableURLRequest -setAllowsCellularAccess:
 */
@property (nonatomic, assign) BOOL allowsCellularAccess;


/** 创建请求的缓存策略. 默认为 NSURLRequestUseProtocolCachePolicy
 * @see NSMutableURLRequest -setCachePolicy:
 *  <ul>
 *     <li> NSURLRequestUseProtocolCachePolicy 基础策略
 *     <li> NSURLRequestReloadIgnoringLocalCacheData 忽略本地缓存
 *     <li> NSURLRequestReloadIgnoringLocalAndRemoteCacheData 无视任何缓存策略，无论是本地的还是远程的，总是从服务器重新下载
 *     <li> NSURLRequestReloadIgnoringCacheData 忽略本地缓存
 *     <li> NSURLRequestReturnCacheDataElseLoad 首先使用缓存，如果没有本地缓存，才从服务器下载
 *     <li> NSURLRequestReturnCacheDataDontLoad 使用本地缓存，从不下载，如果本地没有缓存，则请求失败，此策略多用于离线操作
 *     <li> NSURLRequestReloadRevalidatingCacheData 如果本地缓存是有效的则不下载，其他任何情况都从原地址重新下载 *
 *  </ul>
 */
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;

/** 创建的请求是否应该使用默认的cookie处理；默认为 YES。
 * @see NSMutableURLRequest -setHTTPShouldHandleCookies:
 */
@property (nonatomic, assign) BOOL HTTPShouldHandleCookies;

/** 创建的请求能否在接收之前的传输响应之前继续传输数据；默认为 NO
 * @see NSMutableURLRequest -setHTTPShouldUsePipelining:
 */
@property (nonatomic, assign) BOOL HTTPShouldUsePipelining;


/** 创建请求的网络服务类型；默认 NSURLNetworkServiceTypeDefault
 * @see NSMutableURLRequest -setNetworkServiceType:
 *  <ul>
 *     <li> NSURLNetworkServiceTypeDefault 标准的网络流量，大多数连接应该使用这种服务类型。
 *     <li> NSURLNetworkServiceTypeVoIP 指定该请求用于VoIP服务，内核在你的应用程序处于后台时继续监听传入流量。
 *     <li> NSURLNetworkServiceTypeVideo 指定请求用于语音通信
 *     <li> NSURLNetworkServiceTypeBackground 网络后台传输，优先级不高时可使用。对用户不需要的网络操作可使用
 *     <li> NSURLNetworkServiceTypeVoice   语音传输
 *     <li> NSURLNetworkServiceTypeCallSignaling  电话信号
 *  </ul>
 */
@property (nonatomic, assign) NSURLRequestNetworkServiceType networkServiceType;

/** 请求的超时间隔，默认 60 秒。
 * @see NSMutableURLRequest -setTimeoutInterval:
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

///---------------------------------------
/// @name 配置 HTTP 请求报头
///---------------------------------------

/** HTTP 请求头部信息 ，默认包含以下内容:
 *   <li> `Accept-Language` 包含NSLocale 的 +preferredLanguages 内容
 *   <li> `User-Agent` 带有各种 Bundle 标识符和 OS 名称的内容
 * @discussion 使用 -setValue:forHTTPHeaderField: 添加或删除默认的请求头字段
 */
@property (readonly, nonatomic, strong) NSDictionary <NSString *, NSString *> *HTTPRequestHeaders;

/**  创建具有默认配置的序列化器
 */
+ (instancetype)serializer;

/** 设置 HTTP 客户端创建的请求对象中的请求头部信息。
 * @param field 设置默认值的HTTP头
 * @param value 指定头部的默认值，如果 nil ，删除该header的现有值
 */
- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(NSString *)field;

/** 获取在请求序列化器中设置的HTTP头的值，可能为 nil
 * @param field 默认值的HTTP头
 */
- (nullable NSString *)valueForHTTPHeaderField:(NSString *)field;

/** 授权信息 Authorization，通常出现在对服务器发送的WWW-Authenticate头的应答中，这覆盖了这个头的任何现有值。
 * 用base64编码的用户名和密码将HTTP客户端请求的对象设置为一个基本的身份验证值；主要用于证明客户端有权查看某个资源。
 * 当客户端访问一个页面时，如果收到服务器的响应代码为401（未授权），可以发送一个包含Authorization请求报头域的请求，要求服务器对其进行验证。
 *
 * @param username 认证用户名
 * @param password 认证密码
 */
- (void)setAuthorizationHeaderFieldWithUsername:(NSString *)username password:(NSString *)password;

/** 清除授权信息
 */
- (void)clearAuthorizationHeader;

///-------------------------------------------------------
/// @name 配置查询字符串参数序列化
///-------------------------------------------------------

/** 将参数编码为字符串的HTTP方法，默认为 GET、HEAD 和 DELETE
 */
@property (nonatomic, strong) NSSet <NSString *> *HTTPMethodsEncodingParametersInURI;

/** 设置请求参数序列化类型
 */
- (void)setQueryStringSerializationWithStyle:(AFHTTPRequestQueryStringSerializationStyle)style;

/** 根据指定的 Block 来自定义将参数编码到查询字符串中的方法
 */
- (void)setQueryStringSerializationWithBlock:(nullable NSString * _Nullable (^)(NSURLRequest *request, id parameters, NSError * __autoreleasing *error))block;

///-------------------------------
/// @name 创建请求对象
///-------------------------------

/** 使用指定的 HTTP 方法和 URL 字符串创建一个 NSMutableURLRequest 对象
 * @param method HTTP请求方法，如GET、POST、PUT 或DELETE，不能为 nil
 * @param URLString 用于请求的URL
 * @param parameters 可以附加到 URL 中，也可以设置在HTTP的 request body 中
 * @param error 创建请求时发生的错误。
 *
 * @note 如果HTTP方法是 GET、HEAD 或 DELETE ，parameters 将被附加到URL字符串后面。否则，parameters 将根据 parameterEncoding 属性的值进行编码，并设置为 request body
*/
- (nullable NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                          URLString:(NSString *)URLString
                                         parameters:(nullable id)parameters
                                              error:(NSError * _Nullable __autoreleasing *)error;

/** 使用指定的 HTTP 方法和 URLString 创建一个 NSMutableURLRequest 对象，并使用指定的参数和 formData 构造一个 multipart/form-data HTTP主体
 * @discuss AFMultipartFormData 被自动流处理，直接从磁盘以及内存中的HTTP body读取文件！
 *   处理结束后 NSMutableURLRequest 对象有一个 HTTPBodyStream 属性，此时在该请求对象中不要设置 HTTPBodyStream 或 HTTPBody，因为它将从 body stream 中清除 AFMultipartFormData
 *
 * @param method  HTTP请求方法名，一般都是 POST 请求
 * @param URLString 请求地址
 * @param parameters 被编码到HTTP body中的请求参数
 * @param block 通过 AFMultipartFormData 类型的 formData 来构建请求体
 * @param error 构建请求体出错信息
 */
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(nullable NSDictionary <NSString *, id> *)parameters
                              constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                                  error:(NSError * _Nullable __autoreleasing *)error;

/**
 Creates an `NSMutableURLRequest` by removing the `HTTPBodyStream` from a request, and asynchronously writing its contents into the specified file, invoking the completion handler when finished.

 @param request The multipart form request. The `HTTPBodyStream` property of `request` must not be `nil`.
 @param fileURL The file URL to write multipart form contents to.
 @param handler A handler block to execute.

 @discussion There is a bug in `NSURLSessionTask` that causes requests to not send a `Content-Length` header when streaming contents from an HTTP body, which is notably problematic when interacting with the Amazon S3 webservice. As a workaround, this method takes a request constructed with `multipartFormRequestWithMethod:URLString:parameters:constructingBodyWithBlock:error:`, or any other request with an `HTTPBodyStream`, writes the contents to the specified file and returns a copy of the original request with the `HTTPBodyStream` property set to `nil`. From here, the file can either be passed to `AFURLSessionManager -uploadTaskWithRequest:fromFile:progress:completionHandler:`, or have its contents read into an `NSData` that's assigned to the `HTTPBody` property of the request.

 @see https://github.com/AFNetworking/AFNetworking/issues/1398
 */
- (NSMutableURLRequest *)requestWithMultipartFormRequest:(NSURLRequest *)request
                             writingStreamContentsToFile:(NSURL *)fileURL
                                       completionHandler:(nullable void (^)(NSError * _Nullable error))handler;

@end

#pragma mark -

/**
 The `AFMultipartFormData` protocol defines the methods supported by the parameter in the block argument of `AFHTTPRequestSerializer -multipartFormRequestWithMethod:URLString:parameters:constructingBodyWithBlock:`.
 
 主要用于添加 multipart/form-data 请求的Content-Disposition: file; filename = #{generated filename}; name=#{name}" 和 Content-Type: #{generated mimeType}的请求体域。

 
 */
@protocol AFMultipartFormData

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{generated filename}; name=#{name}"` and `Content-Type: #{generated mimeType}`, followed by the encoded file data and the multipart form boundary.

 The filename and MIME type for this data in the form will be automatically generated, using the last path component of the `fileURL` and system associated MIME type for the `fileURL` extension, respectively.

 @param fileURL The URL corresponding to the file whose content will be appended to the form. This parameter must not be `nil`.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.

 @return `YES` if the file data was successfully appended, otherwise `NO`.
 */
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * _Nullable __autoreleasing *)error;

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}`, followed by the encoded file data and the multipart form boundary.

 @param fileURL The URL corresponding to the file whose content will be appended to the form. This parameter must not be `nil`.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 @param fileName The file name to be used in the `Content-Disposition` header. This parameter must not be `nil`.
 @param mimeType The declared MIME type of the file data. This parameter must not be `nil`.
 @param error If an error occurs, upon return contains an `NSError` object that describes the problem.

 @return `YES` if the file data was successfully appended otherwise `NO`.
 */
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                     mimeType:(NSString *)mimeType
                        error:(NSError * _Nullable __autoreleasing *)error;

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}`, followed by the data from the input stream and the multipart form boundary.

 @param inputStream The input stream to be appended to the form data
 @param name The name to be associated with the specified input stream. This parameter must not be `nil`.
 @param fileName The filename to be associated with the specified input stream. This parameter must not be `nil`.
 @param length The length of the specified input stream in bytes.
 @param mimeType The MIME type of the specified data. (For example, the MIME type for a JPEG image is image/jpeg.) For a list of valid MIME types, see http://www.iana.org/assignments/media-types/. This parameter must not be `nil`.
 */
- (void)appendPartWithInputStream:(nullable NSInputStream *)inputStream
                             name:(NSString *)name
                         fileName:(NSString *)fileName
                           length:(int64_t)length
                         mimeType:(NSString *)mimeType;

/**
 Appends the HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}`, followed by the encoded file data and the multipart form boundary.

 @param data The data to be encoded and appended to the form data.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 @param fileName The filename to be associated with the specified data. This parameter must not be `nil`.
 @param mimeType The MIME type of the specified data. (For example, the MIME type for a JPEG image is image/jpeg.) For a list of valid MIME types, see http://www.iana.org/assignments/media-types/. This parameter must not be `nil`.
 */
- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType;

/**
 Appends the HTTP headers `Content-Disposition: form-data; name=#{name}"`, followed by the encoded data and the multipart form boundary.

 @param data The data to be encoded and appended to the form data.
 @param name The name to be associated with the specified data. This parameter must not be `nil`.
 */

- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name;


/**
 Appends HTTP headers, followed by the encoded data and the multipart form boundary.

 @param headers The HTTP headers to be appended to the form data.
 @param body The data to be encoded and appended to the form data. This parameter must not be `nil`.
 */
- (void)appendPartWithHeaders:(nullable NSDictionary <NSString *, NSString *> *)headers
                         body:(NSData *)body;

/**
 Throttles request bandwidth by limiting the packet size and adding a delay for each chunk read from the upload stream.

 When uploading over a 3G or EDGE connection, requests may fail with "request body stream exhausted". Setting a maximum packet size and delay according to the recommended values (`kAFUploadStream3GSuggestedPacketSize` and `kAFUploadStream3GSuggestedDelay`) lowers the risk of the input stream exceeding its allocated bandwidth. Unfortunately, there is no definite way to distinguish between a 3G, EDGE, or LTE connection over `NSURLConnection`. As such, it is not recommended that you throttle bandwidth based solely on network reachability. Instead, you should consider checking for the "request body stream exhausted" in a failure block, and then retrying the request with throttled bandwidth.

 @param numberOfBytes Maximum packet size, in number of bytes. The default packet size for an input stream is 16kb.
 @param delay Duration of delay each time a packet is read. By default, no delay is set.
 */
- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
                                  delay:(NSTimeInterval)delay;

@end

#pragma mark -

/**
 `AFJSONRequestSerializer` is a subclass of `AFHTTPRequestSerializer` that encodes parameters as JSON using `NSJSONSerialization`, setting the `Content-Type` of the encoded request to `application/json`.
 
 针对JSON类型的序列化优化。
 */
@interface AFJSONRequestSerializer : AFHTTPRequestSerializer

/**
 Options for writing the request JSON data from Foundation objects. For possible values, see the `NSJSONSerialization` documentation section "NSJSONWritingOptions". `0` by default.
 */
@property (nonatomic, assign) NSJSONWritingOptions writingOptions;

/**
 Creates and returns a JSON serializer with specified reading and writing options.

 @param writingOptions The specified JSON writing options.
 */
+ (instancetype)serializerWithWritingOptions:(NSJSONWritingOptions)writingOptions;

@end

#pragma mark -

/**
 `AFPropertyListRequestSerializer` is a subclass of `AFHTTPRequestSerializer` that encodes parameters as JSON using `NSPropertyListSerializer`, setting the `Content-Type` of the encoded request to `application/x-plist`.
 
 针对Plist类型的序列化优化。
 */
@interface AFPropertyListRequestSerializer : AFHTTPRequestSerializer

/**
 The property list format. Possible values are described in "NSPropertyListFormat".
 */
@property (nonatomic, assign) NSPropertyListFormat format;

/**
 @warning The `writeOptions` property is currently unused.
 */
@property (nonatomic, assign) NSPropertyListWriteOptions writeOptions;

/**
 Creates and returns a property list serializer with a specified format, read options, and write options.

 @param format The property list format.
 @param writeOptions The property list write options.

 @warning The `writeOptions` property is currently unused.
 */
+ (instancetype)serializerWithFormat:(NSPropertyListFormat)format
                        writeOptions:(NSPropertyListWriteOptions)writeOptions;

@end

#pragma mark -

///----------------
/// @name Constants
///----------------

/**
 ## Error Domains

 The following error domain is predefined.

 - `NSString * const AFURLRequestSerializationErrorDomain`

 ### Constants

 `AFURLRequestSerializationErrorDomain`
 AFURLRequestSerializer errors. Error codes for `AFURLRequestSerializationErrorDomain` correspond to codes in `NSURLErrorDomain`.
 */
FOUNDATION_EXPORT NSString * const AFURLRequestSerializationErrorDomain;

/**
 ## User info dictionary keys

 These keys may exist in the user info dictionary, in addition to those defined for NSError.

 - `NSString * const AFNetworkingOperationFailingURLRequestErrorKey`

 ### Constants

 `AFNetworkingOperationFailingURLRequestErrorKey`
 The corresponding value is an `NSURLRequest` containing the request of the operation associated with an error. This key is only present in the `AFURLRequestSerializationErrorDomain`.
 */
FOUNDATION_EXPORT NSString * const AFNetworkingOperationFailingURLRequestErrorKey;

/**
 ## Throttling Bandwidth for HTTP Request Input Streams

 @see -throttleBandwidthWithPacketSize:delay:

 ### Constants

 `kAFUploadStream3GSuggestedPacketSize`
 Maximum packet size, in number of bytes. Equal to 16kb.

 `kAFUploadStream3GSuggestedDelay`
 Duration of delay each time a packet is read. Equal to 0.2 seconds.
 */
FOUNDATION_EXPORT NSUInteger const kAFUploadStream3GSuggestedPacketSize;
FOUNDATION_EXPORT NSTimeInterval const kAFUploadStream3GSuggestedDelay;

NS_ASSUME_NONNULL_END


/*
总结
这个类主要实现了对于不同情况的请求的request对象的封装。
尤其是对于multipart/form-data类型的request的封装，简化了我们自己封装过程的痛苦。
如果我们要使用multipart/form-data类型的请求。强烈推荐使用AFHTTPSessionManager对象的AFHTTPRequestSerialization来处理参数的序列化过程。
下面就是使用AFHTTPRequestSerailization序列化和自己拼装的不同：

*/

