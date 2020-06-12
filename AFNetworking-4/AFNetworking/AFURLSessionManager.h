// AFURLSessionManager.h
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

#import "AFURLResponseSerialization.h"
#import "AFURLRequestSerialization.h"
#import "AFSecurityPolicy.h"
#import "AFCompatibilityMacros.h"
#if !TARGET_OS_WATCH
#import "AFNetworkReachabilityManager.h"
#endif

/** AFURLSessionManager 是对 NSURLSession功能 的封装，并遵守 NSURLSessionTaskDelegate、NSURLSessionDataDelegate、NSURLSessionDownloadDelegate 和 NSURLSessionDelegate 等协议！
 *
 * 是 AFHTTPSessionManager 的基类。如果想要为HTTP扩展一些功能，可以考虑将 AFURLSessionManager 子类化。
 *
 * NSURLSession & NSURLSessionTask 委托方法：
 *  <ul>
 *    NSURLSessionDelegate
 *     <li> `-URLSession:didBecomeInvalidWithError:`
 *     <li> `-URLSession:didReceiveChallenge:completionHandler:`
 *     <li> `-URLSessionDidFinishEventsForBackgroundURLSession:`
 *
 *    NSURLSessionTaskDelegate
 *     <li> `-URLSession:willPerformHTTPRedirection:newRequest:completionHandler:`
 *     <li> `-URLSession:task:didReceiveChallenge:completionHandler:`
 *     <li> `-URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:`
 *     <li> `-URLSession:task:needNewBodyStream:`
 *     <li> `-URLSession:task:didCompleteWithError:`
 *
 *    NSURLSessionDataDelegate
 *     <li> `-URLSession:dataTask:didReceiveResponse:completionHandler:`
 *     <li> `-URLSession:dataTask:didBecomeDownloadTask:`
 *     <li> `-URLSession:dataTask:didReceiveData:`
 *     <li> `-URLSession:dataTask:willCacheResponse:completionHandler:`
 *
 *    NSURLSessionDownloadDelegate
 *     <li> `-URLSession:downloadTask:didFinishDownloadingToURL:`
 *     <li> `-URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:`
 *     <li> `-URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes:`
 *  </ul>
 *
 * 如果这些委托方法在子类中被覆盖，它们必须先调用 super 实现
 *
 * 网络状态监控：AFNetworkReachabilityManager
 *
 * NSCoding 说明：已编码的 managers 不包括任何 block 属性。请确保在使用' -initWithCoder: '或' NSKeyedUnarchiver '时设置委托回调块。
 * NSCopying说明： -copy 和 -copywithzone: 返回的 manager 与一个新的 NSURLSession 从原始的配置创建； 因为 blocks 通常强捕获对 self 的引用，拷贝的副本不包括任何委托回调 blocks。
 *
 * @warning 后台会话的 Managers 在使用期间不能被释放；这可以通过单例来实现。
 */

NS_ASSUME_NONNULL_BEGIN

@interface AFURLSessionManager : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate, NSSecureCoding, NSCopying>

/** 网络会话 */
@property (readonly, nonatomic, strong) NSURLSession *session;

/** 为 NSURLSession 配置的操作队列
 * 默认最大并发数为 1 ！ 为何为 1 ？
 * 1、AF2.x 所有的回调是在一条线程，这条线程是AF的常驻线程，而这一条线程正是AF调度request的思想精髓所在，所以第一个目的就是为了和之前版本保持一致。
 * 2、因为跟代理相关的一些操作AF都使用了NSLock。所以就算Queue的并发数设置为n，因为多线程回调，锁的等待，导致所提升的程序速度也并不明显。反而多task回调导致的多线程并发，平白浪费了部分性能。
 而设置Queue的并发数为1，（注：这里虽然回调Queue的并发数为1，仍然会有不止一条线程，但是因为是串行回调，所以同一时间，只会有一条线程在操作AFUrlSessionManager的那些方法。）至少回调的事件，是不需要多线程并发的。回调没有了NSLock的等待时间，所以对时间并没有多大的影响。（注：但是还是会有多线程的操作的，因为设置刚开始调起请求的时候，是在主线程的，而回调则是串行分线程。）
 */
@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;

/** 工具类：将从服务器接收到的 GET/POST 请求的响应数据序列化，不能为 nil。
 */
@property (nonatomic, strong) id <AFURLResponseSerialization> responseSerializer;

///-------------------------------
/// @name Managing Security Policy
///-------------------------------


/** 验证 HTTPS 请求的证书是否有效，涉及用户敏感或隐私数据或金融信息的应用全部网络连接最好采用SSL的HTTPS连接。
 * AFSSLPinningModeNone  不使用固定证书（本地）验证服务器。直接从客户端系统中的受信任颁发机构 CA 列表中去验证
 * AFSSLPinningModePublicKey 对服务器返回的证书中的PublicKey进行验证，通过则通过，否则不通过
 * AFSSLPinningModeCertificate 对服务器返回的证书同本地证书全部进行校验，通过则通过，否则不通过
 */
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

#if !TARGET_OS_WATCH
///--------------------------------------
/// @name 监测网络状态
///--------------------------------------

/** 网络监测管理器
 */
@property (readwrite, nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;
#endif

///----------------------------
/// @name 获取 Session Tasks
///----------------------------

/** 数据、上传、下载任务当前由NSURLSession 运行
 */
@property (readonly, nonatomic, strong) NSArray <NSURLSessionTask *> *tasks;

/** 由 NSURLSession 运行的数据任务
 */
@property (readonly, nonatomic, strong) NSArray <NSURLSessionDataTask *> *dataTasks;

/** 由 NSURLSession 运行的上传任务
 */
@property (readonly, nonatomic, strong) NSArray <NSURLSessionUploadTask *> *uploadTasks;

/** 由 NSURLSession 运行的下载任务
 */
@property (readonly, nonatomic, strong) NSArray <NSURLSessionDownloadTask *> *downloadTasks;

///-------------------------------
/// @name Managing 回调队列
///-------------------------------

/** 请求完成后的回调队列，默认为 NULL，在主线程处理；
 * 如果请求到的数据还需要在分线程解析，可以设置该队列，解析完成后自己回到主队列去刷新UI！
 */
@property (nonatomic, strong, nullable) dispatch_queue_t completionQueue;

/** 请求完成后的调度组，默认为 NULL；
 */
@property (nonatomic, strong, nullable) dispatch_group_t completionGroup;

///---------------------
/// @name 初始化
///---------------------

/** 使用指定配置创建管理器
 * @param configuration 用于 NSURLSession 的配置
 */
- (instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

/** 使 NSURLSession 会话无效：可选地取消挂起的任务并可选地重置指定会话。
 * @param cancelPendingTasks  是否取消挂起的任务
 * @param resetSession    是否重置 NSURLSession
 */
- (void)invalidateSessionCancelingTasks:(BOOL)cancelPendingTasks resetSession:(BOOL)resetSession;

///-------------------------
/// @name 运行 NSURLSessionDataTask
///-------------------------

/** 使用指定的请求创建一个 NSURLSessionDataTask
 * @param request HTTP请求
 * @param uploadProgressBlock 上传进度监控。注意，此块是在会话队列上调用的，而不是在主队列上。
 * @param downloadProgressBlock 下载进度监控，注意，此块是在会话队列上调用的，而不是在主队列上。
 * @param completionHandler 任务完成时的回调
 */
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                               uploadProgress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
                             downloadProgress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                            completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject,  NSError * _Nullable error))completionHandler;

///---------------------------
/// @name 运行 NSURLSessionUploadTask
///---------------------------

/** 使用指定的本地文件请求创建一个 NSURLSessionUploadTask
 * @param fileURL 要上传的本地文件的URL
 * @see `attemptsToRecreateUploadTasksForBackgroundSessions`
 */
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromFile:(NSURL *)fileURL
                                         progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject, NSError  * _Nullable error))completionHandler;

/** 使用指定的 HTTP body 请求创建一个 NSURLSessionUploadTask
 * @param bodyData 要上传的HTTP主体的数据
 */
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(nullable NSData *)bodyData
                                         progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject, NSError * _Nullable error))completionHandler;

/** 使用指定的 Streamed 请求创建一个 NSURLSessionUploadTask
 */
- (NSURLSessionUploadTask *)uploadTaskWithStreamedRequest:(NSURLRequest *)request
                                                 progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
                                        completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject, NSError * _Nullable error))completionHandler;

///-----------------------------
/// @name 运行 NSURLSessionDownloadTask
///-----------------------------

/** 使用指定请求创建一个 NSURLSessionDownloadTask
 *
 * @param destination 确定下载文件的目标，接受两个参数 targetPath 和 response，并返回结果下载所需的文件地址URL。下载过程中使用的临时文件将被移动到返回的URL后自动删除。
 *
 * @warning 如果在 iOS 后台使用 NSURLSessionConfiguration ，这些 block 将在应用程序终止时丢失。后台会话最好使用 -setDownloadTaskDidFinishDownloadingBlock: 来指定保存下载文件的URL，而不是该方法的destinationBlock。
 */
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                             progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                          destination:(nullable NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                    completionHandler:(nullable void (^)(NSURLResponse *response, NSURL * _Nullable filePath, NSError * _Nullable error))completionHandler;

/** 使用 resumeData 创建一个 NSURLSessionDownloadTask
 * @param resumeData 用于恢复下载的数据
 */
- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData
                                                progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                             destination:(nullable NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                       completionHandler:(nullable void (^)(NSURLResponse *response, NSURL * _Nullable filePath, NSError * _Nullable error))completionHandler;

///---------------------------------
/// @name 获取任务进度
///---------------------------------

/** 获取指定任务的上传进度
 * @param task不能为 nil
 */
- (nullable NSProgress *)uploadProgressForTask:(NSURLSessionTask *)task;

/** 获取指定任务的下载进度 */
- (nullable NSProgress *)downloadProgressForTask:(NSURLSessionTask *)task;

///-----------------------------------------
/// @name 设置 NSURLSessionDelegate 回调
///-----------------------------------------

/** NSURLSession 无效时执行的Block
 *@note 在 NSURLSessionDelegate 的 -URLSession:didBecomeInvalidWithError: 方法中调用
 */
- (void)setSessionDidBecomeInvalidBlock:(nullable void (^)(NSURLSession *session, NSError *error))block;

/** NSURLSession 需要验证身份要执行的Block
 * @note 在 NSURLSessionDelegate 的 -URLSession:didReceiveChallenge:completionHandler: 方法中调用
 *
 * @warning 自己实现 AuthenticationChallenge 完全绕过了AFNetworking在 AFSecurityPolicy 中定义的安全策略。
 *       在实现自定义 AuthenticationChallenge 之前，请确保充分理解其中的含义。
 *       如果不想绕过 AFNetworking 的安全策略，可以使用 -setAuthenticationChallengeHandler:
 *
 * @see -securityPolicy
 * @see -setAuthenticationChallengeHandler:
 */
- (void)setSessionDidReceiveAuthenticationChallengeBlock:(nullable NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * _Nullable __autoreleasing * _Nullable credential))block;

///--------------------------------------
/// @name 设置 NSURLSessionTaskDelegate 回调
///--------------------------------------

/** 当任务需要一个新的 BodyStream 发送到远程服务器时要执行的Block，
 * @note 在 NSURLSessionTaskDelegate 的 -URLSession:task:needNewBodyStream: 方法中调用
 */
- (void)setTaskNeedNewBodyStreamBlock:(nullable NSInputStream * (^)(NSURLSession *session, NSURLSessionTask *task))block;

/** 当 HTTP 请求试图重定向到另一个URL时要执行的Block，
 * @note 在 NSURLSessionTaskDelegate 的 -URLSession:willPerformHTTPRedirection:newRequest:completionHandler: 方法中调用
 */
- (void)setTaskWillPerformHTTPRedirectionBlock:(nullable NSURLRequest * _Nullable (^)(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request))block;

/** 当会话任务接收到特定于请求的身份验证挑战时要执行的Block
 * @note 在 NSURLSessionTaskDelegate 的 -URLSession:task:didReceiveChallenge:completionHandler: 方法中调用
 *
 * @param authenticationChallengeHandler 当会话任务接收到特定于请求的身份验证挑战时要执行的Block
 *
 * 在身份验证处理时，应该首先检查 challenge.protectionSpace.authenticationMethod 来决定是自己处理身份验证挑战，还是想让AFNetworking来处理它。
 * 如果希望AFNetworking处理，只需返回 @(NSURLSessionAuthChallengePerformDefaultHandling)
 *     例如，希望AFNetworking 安全策略定义的 authenticationMethod==NSURLAuthenticationMethodServerTrust。
 *
 * 如果想自己处理，有以下四个选择:
 * 1. authentication challenge handler 返回 nil。提供一个用户界面来让用户输入他们的凭证，调用带有配置和凭证的 completionHandler。
 * 2. authentication challenge handler 返回 NSError；如果需要终止错误的身份验证，此时不必调用completionHandler。
 * 3. authentication challenge handler 返回 NSURLCredential 用于完成验证。当不需要在显示用户界面的情况下获得凭据时不必调用completionHandler。
 * 4. 返回NSURLSessionAuthChallengeDisposition 的字面量。如：
 *       @(NSURLSessionAuthChallengePerformDefaultHandling),
 *       @(NSURLSessionAuthChallengeCancelAuthenticationChallenge)
 *       @(NSURLSessionAuthChallengeRejectProtectionSpace)
 *
 * 如果authentication challenge handler 返回其他内容，将引发异常。
 *
 * @see -securityPolicy
 */
- (void)setAuthenticationChallengeHandler:(id (^)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, void (^completionHandler)(NSURLSessionAuthChallengeDisposition , NSURLCredential * _Nullable)))authenticationChallengeHandler;

/** 设置一个定期执行的Block来监测上传进度
 * @note 在 NSURLSessionTaskDelegate 的 -URLSession:task:didSendBodyData:totalBytesSent:totalbytesexpectedend: 方法中调用
 * @param block 当不确定的字节数被上传到服务器时多次调用，并将在主线程上执行；
 */
- (void)setTaskDidSendBodyDataBlock:(nullable void (^)(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))block;

/**任务完成时要执行的Block，
 * @note 在 NSURLSessionTaskDelegate 的 -URLSession:task:didCompleteWithError: 方法中调用
 */
- (void)setTaskDidCompleteBlock:(nullable void (^)(NSURLSession *session, NSURLSessionTask *task, NSError * _Nullable error))block;

/** 当特定任务相关的 metrics 完成时要执行的Block
 * @note 在 NSURLSessionTaskDelegate 的 -URLSession:task:didFinishCollectingMetrics: 方法中调用
 */
#if AF_CAN_INCLUDE_SESSION_TASK_METRICS
- (void)setTaskDidFinishCollectingMetricsBlock:(nullable void (^)(NSURLSession *session, NSURLSessionTask *task, NSURLSessionTaskMetrics * _Nullable metrics))block AF_API_AVAILABLE(ios(10), macosx(10.12), watchos(3), tvos(10));
#endif
///-------------------------------------------
/// @name 设置 NSURLSessionDataDelegate 回调
///-------------------------------------------

/** 接收到响应数据时要执行的Block
 * @note 在 NSURLSessionDataDelegate 的 -URLSession:dataTask:didReceiveResponse:completionHandler: 方法中调用
 */
- (void)setDataTaskDidReceiveResponseBlock:(nullable NSURLSessionResponseDisposition (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response))block;

/** dataTask 变成 downloadTask 时执行的Block
 * @note 在 NSURLSessionDataDelegate 的 -URLSession:dataTask:didBecomeDownloadTask: 方法中调用
 */
- (void)setDataTaskDidBecomeDownloadTaskBlock:(nullable void (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask))block;

/** 接收到数据时要执行的Block
 * @note 在 NSURLSessionDataDelegate 的 -URLSession:dataTask:didReceiveData: 方法中调用
 * @param block 从服务器下载数据时被多次调用的Block ，将在 AFURLSessionManager.operationQueue 执行。
 */
- (void)setDataTaskDidReceiveDataBlock:(nullable void (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data))block;

/** 用于确定 dataTask 缓存行为的Block
 * @note 在 NSURLSessionDataDelegate 的 -URLSession:dataTask:willCacheResponse:completionHandler: 方法中调用
 */
- (void)setDataTaskWillCacheResponseBlock:(nullable NSCachedURLResponse * (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSCachedURLResponse *proposedResponse))block;

/** 当所有排队等待 NSURLSession 的消息都被传递后执行的Block
 * @note 在 NSURLSessionDataDelegate 的 -URLSessionDidFinishEventsForBackgroundURLSession: 方法中调用
 */
- (void)setDidFinishEventsForBackgroundURLSessionBlock:(nullable void (^)(NSURLSession *session))block AF_API_UNAVAILABLE(macos);

///-----------------------------------------------
/// @name 设置 NSURLSessionDownloadDelegate 回调
///-----------------------------------------------

/** downloadTask 完成下载后执行的Block
 * @note 在 NSURLSessionDownloadDelegate 的 -URLSession:downloadTask:didFinishDownloadingToURL: 方法中调用
 * @note 如果 fileManager 将临时文件移动到目的地时遇到错误，将发送通知 AFURLSessionDownloadTaskDidFailToMoveFileNotification ，字典 userInfo 包含下载任务，以及错误信息。
 */
- (void)setDownloadTaskDidFinishDownloadingBlock:(nullable NSURL * _Nullable  (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location))block;

/** 一个定期执行的Block 用于监测下载进度
 * @note 在 NSURLSessionDownloadDelegate 的 -URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite: 方法中调用
 * @param block 从服务器下载数据时被多次调用的Block ，将在 AFURLSessionManager.operationQueue 执行。
 */
- (void)setDownloadTaskDidWriteDataBlock:(nullable void (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite))block;

/** 中断的下载任务被恢复时要执行的Block
 * @note 在 NSURLSessionDownloadDelegate 的 -URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes: 方法中调用
 */
- (void)setDownloadTaskDidResumeBlock:(nullable void (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t fileOffset, int64_t expectedTotalBytes))block;

@end

///--------------------
/// @name 通知：信息包含在字典 userInfo 中
///--------------------

/** 任务中断后重新开始时发送
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidResumeNotification;

/** 任务完成时发送
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidCompleteNotification;

/** 任务暂停时发送
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidSuspendNotification;

/** session 无效时发送
 */
FOUNDATION_EXPORT NSString * const AFURLSessionDidInvalidateNotification;

/** 当 NSURLSessionDownloadTask 将下载文件从临时目录移动到指定目录时发送
 */
FOUNDATION_EXPORT NSString * const AFURLSessionDownloadTaskDidMoveFileSuccessfullyNotification;

/** 当 NSURLSessionDownloadTask 将下载文件从临时目录移动到指定目录遇到错误时发送
 */
FOUNDATION_EXPORT NSString * const AFURLSessionDownloadTaskDidFailToMoveFileNotification;

/** NSURLSessionDataTask 的响应数据
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidCompleteResponseDataKey;

/** 任务的序列化响应对象
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidCompleteSerializedResponseKey;

/** 任务关联的响应序列化器
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidCompleteResponseSerializerKey;

/** 下载任务关联的文件路径。如果响应数据已直接存储到磁盘，则发送该通知！
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidCompleteAssetPathKey;

/** 与任务或响应数据序列化相关的错误。
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidCompleteErrorKey;

/** 从下载任务获取的指标
 */
FOUNDATION_EXPORT NSString * const AFNetworkingTaskDidCompleteSessionTaskMetrics;

NS_ASSUME_NONNULL_END
