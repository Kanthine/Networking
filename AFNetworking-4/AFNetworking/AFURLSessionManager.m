// AFURLSessionManager.m
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

#import "AFURLSessionManager.h"
#import <objc/runtime.h>

//创建一个串行队列单例
static dispatch_queue_t url_session_manager_processing_queue() {
    static dispatch_queue_t af_url_session_manager_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_url_session_manager_processing_queue = dispatch_queue_create("com.alamofire.networking.session.manager.processing", DISPATCH_QUEUE_CONCURRENT);
    });
    return af_url_session_manager_processing_queue;
}

///创建一个任务完成后的并发队列单例
static dispatch_group_t url_session_manager_completion_group() {
    static dispatch_group_t af_url_session_manager_completion_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_url_session_manager_completion_group = dispatch_group_create();
    });

    return af_url_session_manager_completion_group;
}

/********************  通知  *********************/

//任务开始的通知
NSString * const AFNetworkingTaskDidResumeNotification = @"com.alamofire.networking.task.resume";
//任务完成的通知
NSString * const AFNetworkingTaskDidCompleteNotification = @"com.alamofire.networking.task.complete";
//任务暂停的通知
NSString * const AFNetworkingTaskDidSuspendNotification = @"com.alamofire.networking.task.suspend";
//使任务失效的通知
NSString * const AFURLSessionDidInvalidateNotification = @"com.alamofire.networking.session.invalidate";
//下载文件移动成功的通知
NSString * const AFURLSessionDownloadTaskDidMoveFileSuccessfullyNotification = @"com.alamofire.networking.session.download.file-manager-succeed";
//下载文件移动失败的通知
NSString * const AFURLSessionDownloadTaskDidFailToMoveFileNotification = @"com.alamofire.networking.session.download.file-manager-error";

NSString * const AFNetworkingTaskDidCompleteSerializedResponseKey = @"com.alamofire.networking.task.complete.serializedresponse";
NSString * const AFNetworkingTaskDidCompleteResponseSerializerKey = @"com.alamofire.networking.task.complete.responseserializer";
NSString * const AFNetworkingTaskDidCompleteResponseDataKey = @"com.alamofire.networking.complete.finish.responsedata";
NSString * const AFNetworkingTaskDidCompleteErrorKey = @"com.alamofire.networking.task.complete.error";
NSString * const AFNetworkingTaskDidCompleteAssetPathKey = @"com.alamofire.networking.task.complete.assetpath";
NSString * const AFNetworkingTaskDidCompleteSessionTaskMetrics = @"com.alamofire.networking.complete.sessiontaskmetrics";

static NSString * const AFURLSessionManagerLockName = @"com.alamofire.networking.session.manager.lock";

typedef void (^AFURLSessionDidBecomeInvalidBlock)(NSURLSession *session, NSError *error);
typedef NSURLSessionAuthChallengeDisposition (^AFURLSessionDidReceiveAuthenticationChallengeBlock)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential);

///重定向
typedef NSURLRequest * (^AFURLSessionTaskWillPerformHTTPRedirectionBlock)(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request);
typedef NSURLSessionAuthChallengeDisposition (^AFURLSessionTaskDidReceiveAuthenticationChallengeBlock)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential);
typedef id (^AFURLSessionTaskAuthenticationChallengeBlock)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, void (^completionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential));

///后台完成的事件
typedef void (^AFURLSessionDidFinishEventsForBackgroundURLSessionBlock)(NSURLSession *session);

typedef NSInputStream * (^AFURLSessionTaskNeedNewBodyStreamBlock)(NSURLSession *session, NSURLSessionTask *task);
typedef void (^AFURLSessionTaskDidSendBodyDataBlock)(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend);
typedef void (^AFURLSessionTaskDidCompleteBlock)(NSURLSession *session, NSURLSessionTask *task, NSError *error);
#if AF_CAN_INCLUDE_SESSION_TASK_METRICS
typedef void (^AFURLSessionTaskDidFinishCollectingMetricsBlock)(NSURLSession *session, NSURLSessionTask *task, NSURLSessionTaskMetrics * metrics) AF_API_AVAILABLE(ios(10), macosx(10.12), watchos(3), tvos(10));
#endif

typedef NSURLSessionResponseDisposition (^AFURLSessionDataTaskDidReceiveResponseBlock)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response);
typedef void (^AFURLSessionDataTaskDidBecomeDownloadTaskBlock)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask);
typedef void (^AFURLSessionDataTaskDidReceiveDataBlock)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data);
typedef NSCachedURLResponse * (^AFURLSessionDataTaskWillCacheResponseBlock)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSCachedURLResponse *proposedResponse);

typedef NSURL * (^AFURLSessionDownloadTaskDidFinishDownloadingBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location);
typedef void (^AFURLSessionDownloadTaskDidWriteDataBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);
typedef void (^AFURLSessionDownloadTaskDidResumeBlock)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t fileOffset, int64_t expectedTotalBytes);
typedef void (^AFURLSessionTaskProgressBlock)(NSProgress *);

typedef void (^AFURLSessionTaskCompletionHandler)(NSURLResponse *response, id responseObject, NSError *error);

#pragma mark -

/** 代理：
 */
@interface AFURLSessionManagerTaskDelegate : NSObject <NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>
- (instancetype)initWithTask:(NSURLSessionTask *)task;
@property (nonatomic, weak) AFURLSessionManager *manager;//弱引用
@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, strong) NSProgress *uploadProgress;//上传进度
@property (nonatomic, strong) NSProgress *downloadProgress;//下载进度
@property (nonatomic, copy) NSURL *downloadFileURL;//下载文件地址
#if AF_CAN_INCLUDE_SESSION_TASK_METRICS
@property (nonatomic, strong) NSURLSessionTaskMetrics *sessionTaskMetrics AF_API_AVAILABLE(ios(10), macosx(10.12), watchos(3), tvos(10));
#endif
@property (nonatomic, copy) AFURLSessionDownloadTaskDidFinishDownloadingBlock downloadTaskDidFinishDownloading;
@property (nonatomic, copy) AFURLSessionTaskProgressBlock uploadProgressBlock;
@property (nonatomic, copy) AFURLSessionTaskProgressBlock downloadProgressBlock;
@property (nonatomic, copy) AFURLSessionTaskCompletionHandler completionHandler;
@end

@implementation AFURLSessionManagerTaskDelegate

- (instancetype)initWithTask:(NSURLSessionTask *)task {
    self = [super init];
    if (!self) {
        return nil;
    }
    _mutableData = [NSMutableData data];
    _uploadProgress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
    _downloadProgress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
    
    __weak __typeof__(task) weakTask = task;
    for (NSProgress *progress in @[ _uploadProgress, _downloadProgress ]){
        progress.totalUnitCount = NSURLSessionTransferSizeUnknown;
        progress.cancellable = YES;
        progress.cancellationHandler = ^{
            [weakTask cancel];
        };
        progress.pausable = YES;
        progress.pausingHandler = ^{
            [weakTask suspend];
        };
#if AF_CAN_USE_AT_AVAILABLE
        if (@available(macOS 10.11, *))
#else
        if ([progress respondsToSelector:@selector(setResumingHandler:)])
#endif
        {
            progress.resumingHandler = ^{
                [weakTask resume];
            };
        }
        
        [progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                      options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)dealloc {
    [self.downloadProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
    [self.uploadProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted))];
}

#pragma mark - NSProgress Tracking

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
   if ([object isEqual:self.downloadProgress]) {
        if (self.downloadProgressBlock) {
            self.downloadProgressBlock(object);
        }
    }
    else if ([object isEqual:self.uploadProgress]) {
        if (self.uploadProgressBlock) {
            self.uploadProgressBlock(object);
        }
    }
}

static const void * const AuthenticationChallengeErrorKey = &AuthenticationChallengeErrorKey;

#pragma mark - NSURLSessionTaskDelegate

/* AF实现的代理！被从urlsession那转发到这 当 task 执行完成后，会调用此代理方法：
 这个方法大概做了以下几件事：
 1、生成了一个存储这个task相关信息的字典：userInfo，这个字典是用来作为发送任务完成的通知的参数。
   判断了参数error的值，来区分请求成功还是失败。
   如果成功则在一个AF的并行queue中，去做数据解析等后续操作：
   注意AF的优化的点，虽然代理回调是串行的。但是数据解析这种费时操作，确是用并行线程来做的。
2、然后根据我们一开始设置的responseSerializer来解析data。如果解析成功，调用成功的回调，否则调用失败的回调。
*/
- (void)URLSession:(__unused NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    //由于在初始化 manager 时 设置 self.operationQueue，故而：代理内部方法在任意分线程执行

    //1）强引用self.manager，防止被提前释放；因为self.manager声明为weak,类似Block
    error = objc_getAssociatedObject(task, AuthenticationChallengeErrorKey) ?: error;
    __strong AFURLSessionManager *manager = self.manager;

    __block id responseObject = nil;

    //用来存储一些相关信息，来发送通知用的
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
     //存储responseSerializer响应解析对象
    userInfo[AFNetworkingTaskDidCompleteResponseSerializerKey] = manager.responseSerializer;

    //Performance Improvement from #2672
    //注意这行代码的用法，感觉写的很Nice...把请求到的数据data传出去，然后就不要这个值了释放内存
    NSData *data = nil;
    if (self.mutableData) {
        data = [self.mutableData copy];
        //We no longer need the reference, so nil it out to gain back some memory.
        self.mutableData = nil;
    }

#if AF_CAN_USE_AT_AVAILABLE && AF_CAN_INCLUDE_SESSION_TASK_METRICS
    if (@available(iOS 10, macOS 10.12, watchOS 3, tvOS 10, *)) {
        if (self.sessionTaskMetrics) {
            userInfo[AFNetworkingTaskDidCompleteSessionTaskMetrics] = self.sessionTaskMetrics;
        }
    }
#endif

     //继续给userinfo填数据
    if (self.downloadFileURL) {
        userInfo[AFNetworkingTaskDidCompleteAssetPathKey] = self.downloadFileURL;
    } else if (data) {
        userInfo[AFNetworkingTaskDidCompleteResponseDataKey] = data;
    }

    //错误处理
    if (error) {
        userInfo[AFNetworkingTaskDidCompleteErrorKey] = error;

        // ? 与 : 之间省略的应该是?之前表达式的值，而不是省略的表达式。
        //可以自己自定义完成组 和自定义完成queue,完成回调
        dispatch_group_async(manager.completionGroup ?: url_session_manager_completion_group(), manager.completionQueue ?: dispatch_get_main_queue(), ^{
            if (self.completionHandler) {
                self.completionHandler(task.response, responseObject, error);
            }

            //主线程中发送完成通知
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingTaskDidCompleteNotification object:task userInfo:userInfo];
            });
        });
    } else {
        
        //url_session_manager_processing_queue AF的并行队列
        dispatch_async(url_session_manager_processing_queue(), ^{
            NSError *serializationError = nil;
            
            //解析数据
            responseObject = [manager.responseSerializer responseObjectForResponse:task.response data:data error:&serializationError];

            if (self.downloadFileURL) {//如果是下载文件，那么responseObject为下载的路径
                responseObject = self.downloadFileURL;
            }

            if (responseObject) {//写入userInfo
                userInfo[AFNetworkingTaskDidCompleteSerializedResponseKey] = responseObject;
            }

            if (serializationError) { //如果解析错误
                userInfo[AFNetworkingTaskDidCompleteErrorKey] = serializationError;
            }

             //回调结果
            dispatch_group_async(manager.completionGroup ?: url_session_manager_completion_group(), manager.completionQueue ?: dispatch_get_main_queue(), ^{
                if (self.completionHandler) {
                    self.completionHandler(task.response, responseObject, serializationError);
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingTaskDidCompleteNotification object:task userInfo:userInfo];
                });
            });
        });
    }
}

#if AF_CAN_INCLUDE_SESSION_TASK_METRICS
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics AF_API_AVAILABLE(ios(10), macosx(10.12), watchos(3), tvos(10)) {
    self.sessionTaskMetrics = metrics;
}
#endif

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(__unused NSURLSession *)session
          dataTask:(__unused NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    self.downloadProgress.totalUnitCount = dataTask.countOfBytesExpectedToReceive;
    self.downloadProgress.completedUnitCount = dataTask.countOfBytesReceived;

    [self.mutableData appendData:data];//拼接数据
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    
    self.uploadProgress.totalUnitCount = task.countOfBytesExpectedToSend;
    self.uploadProgress.completedUnitCount = task.countOfBytesSent;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    self.downloadProgress.totalUnitCount = totalBytesExpectedToWrite;
    self.downloadProgress.completedUnitCount = totalBytesWritten;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes{
    
    self.downloadProgress.totalUnitCount = expectedTotalBytes;
    self.downloadProgress.completedUnitCount = fileOffset;
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    self.downloadFileURL = nil;

    if (self.downloadTaskDidFinishDownloading) { //AF代理的自定义Block
        
        //得到自定义下载路径
        self.downloadFileURL = self.downloadTaskDidFinishDownloading(session, downloadTask, location);
        if (self.downloadFileURL) {
            NSError *fileManagerError = nil;

            if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:self.downloadFileURL error:&fileManagerError]) { //把下载路径移动到我们自定义的下载路径
                
                 //错误发通知
                [[NSNotificationCenter defaultCenter] postNotificationName:AFURLSessionDownloadTaskDidFailToMoveFileNotification object:downloadTask userInfo:fileManagerError.userInfo];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:AFURLSessionDownloadTaskDidMoveFileSuccessfullyNotification object:downloadTask userInfo:nil];
            }
        }
    }
}

@end

#pragma mark -

/** 解决 NSURLSessionTask 的 state 相关的键值问题
 *
 *  See:
 *  - https://github.com/AFNetworking/AFNetworking/issues/1477
 *  - https://github.com/AFNetworking/AFNetworking/issues/2638
 *  - https://github.com/AFNetworking/AFNetworking/pull/2702
 */

static inline void af_swizzleSelector(Class theClass, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(theClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(theClass, swizzledSelector);
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

static inline BOOL af_addMethod(Class theClass, SEL selector, Method method) {
    return class_addMethod(theClass, selector,  method_getImplementation(method),  method_getTypeEncoding(method));
}

static NSString * const AFNSURLSessionTaskDidResumeNotification  = @"com.alamofire.networking.nsurlsessiontask.resume";
static NSString * const AFNSURLSessionTaskDidSuspendNotification = @"com.alamofire.networking.nsurlsessiontask.suspend";

/** 类 _AFURLSessionTaskSwizzling 主要用于替换 NSURLSession 的 -resume 和 -suspend 方法
 */
@interface _AFURLSessionTaskSwizzling : NSObject
@end
@implementation _AFURLSessionTaskSwizzling

/** iOS7 和 iOS8 在 NSURLSessionTask 的实现略有不同，这使得下面的代码有点复杂；构建可能多地单元测试以尽验证这种行为：
 * 以下是我们所知道的:
 *  <li> NSURLSessionTasks 是通过类簇实现的，这意味着从API请求的类实际上不是将返回的类；
 *  <li> 简单引用 [NSURLSessionTask class] 无用；需要通过 NSURLSession 来创建 NSURLSessionTask 对象，并从那里获取类；
 *  <li> 在 iOS7 上，localDataTask 是 __NSCFLocalDataTask ，它继承自 __NSCFLocalSessionTask，它继承自 __NSCFURLSessionTask；
 *  <li> 在 iOS8 上，localDataTask是 __NSCFLocalDataTask，它继承自 __NSCFLocalSessionTask，继承自 NSURLSessionTask；
 *  <li> 在 iOS7 上，“余下的 __NSCFLocalSessionTask 和 __NSCFURLSessionTask 是仅有的实现 -resume 和 -suspend 的类，而 __NSCFLocalSessionTask 不调用 super 。这意味着两个类都需要 swizzled。
 *  <li> 在 iOS8 上，NSURLSessionTask 是唯一实现 -resume 和 -suspend 的类。这意味着这是唯一需要 swizzled 的类。
 *  <li> 由于 NSURLSessionTask 没有涉及到每个版本的iOS的类层次结构，它更容易添加 swizled 方法到一个虚拟类并在那里管理它们。
 *
 *
 * 一些假设:
 *  <li> 没有实现 -resume 或 -suspend 调用 super。如果这在 iOS 的未来版本中发生变化，我们需要处理它；
 *  <li> 没有后台任务类 override -resume 或 -suspend ；
 *
 * 目前的解决方案:
 *  <1> 通过请求 dataTask 的 NSURLSession 实例来获取 __NSCFLocalDataTask 实例
 *  <2> 获取一个指向 -af_resume 原始实现的 IMP 指针
 *  <3> 检查当前类是否有 -resume 的实现。如果有，继续步骤4
 *  <4> 获取当前类的 superClass
 *  <5> 获取当前类 -resume 实现的 IMP 指针
 *  <6> 获取指向当前 -resume 的 superClass 指针
 *  <7> 如果当前类实现的 -resume 不等于 父类实现的 -resume ，并且 -resume 的当前实现不等于 -af_resume 的原始实现，则对方法 swizzle
 *  <8> 将当前类设置为 superClass类，并重复步骤 3-8；
*/
+ (void)load {
    if (NSClassFromString(@"NSURLSessionTask")) {

        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
        NSURLSessionDataTask *localDataTask = [session dataTaskWithURL:nil];
#pragma clang diagnostic pop
        IMP originalAFResumeIMP = method_getImplementation(class_getInstanceMethod([self class], @selector(af_resume)));
        Class currentClass = [localDataTask class];
        
        while (class_getInstanceMethod(currentClass, @selector(resume))) {
            Class superClass = [currentClass superclass];
            IMP classResumeIMP = method_getImplementation(class_getInstanceMethod(currentClass, @selector(resume)));
            IMP superclassResumeIMP = method_getImplementation(class_getInstanceMethod(superClass, @selector(resume)));
            if (classResumeIMP != superclassResumeIMP &&
                originalAFResumeIMP != classResumeIMP) {
                [self swizzleResumeAndSuspendMethodForClass:currentClass];
            }
            currentClass = [currentClass superclass];
        }
        
        [localDataTask cancel];
        [session finishTasksAndInvalidate];
    }
}

+ (void)swizzleResumeAndSuspendMethodForClass:(Class)theClass {
    Method afResumeMethod = class_getInstanceMethod(self, @selector(af_resume));
    Method afSuspendMethod = class_getInstanceMethod(self, @selector(af_suspend));

    if (af_addMethod(theClass, @selector(af_resume), afResumeMethod)) {
        af_swizzleSelector(theClass, @selector(resume), @selector(af_resume));
    }

    if (af_addMethod(theClass, @selector(af_suspend), afSuspendMethod)) {
        af_swizzleSelector(theClass, @selector(suspend), @selector(af_suspend));
    }
}

- (NSURLSessionTaskState)state {
    NSAssert(NO, @"State method should never be called in the actual dummy class");
    return NSURLSessionTaskStateCanceling;
}

//被替换掉的方法，只要 Task 开启或者暂停，都会执行
- (void)af_resume {
    NSAssert([self respondsToSelector:@selector(state)], @"Does not respond to state");
    NSURLSessionTaskState state = [self state];
    [self af_resume];
    
    if (state != NSURLSessionTaskStateRunning) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AFNSURLSessionTaskDidResumeNotification object:self];
    }
}

- (void)af_suspend {
    NSAssert([self respondsToSelector:@selector(state)], @"Does not respond to state");
    NSURLSessionTaskState state = [self state];
    [self af_suspend];
    
    if (state != NSURLSessionTaskStateSuspended) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AFNSURLSessionTaskDidSuspendNotification object:self];
    }
}
@end

#pragma mark -

@interface AFURLSessionManager ()
// 定义了NSURLSession中网络请求的行为和策略，如超时时间、缓存策略等
@property (readwrite, nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;

///回调代理的线程队列
@property (readwrite, nonatomic, strong) NSOperationQueue *operationQueue;

/// NSURLSession本身是不会进行请求的，而是通过创建task的形式进行网络请求（resume()方法的调用），同一个NSURLSession可以创建多个task，并且这些task之间的cache和cookie是共享的
@property (readwrite, nonatomic, strong) NSURLSession *session;

//用来让每一个请求task和我们自定义的AF代理来建立映射用的，其实AF对task的代理进行了一个封装，并且转发代理到AF自定义的代理
@property (readwrite, nonatomic, strong) NSMutableDictionary *mutableTaskDelegatesKeyedByTaskIdentifier;
@property (readonly, nonatomic, copy) NSString *taskDescriptionForSessionTasks;
@property (readwrite, nonatomic, strong) NSLock *lock;
@property (readwrite, nonatomic, copy) AFURLSessionDidBecomeInvalidBlock sessionDidBecomeInvalid;
@property (readwrite, nonatomic, copy) AFURLSessionDidReceiveAuthenticationChallengeBlock sessionDidReceiveAuthenticationChallenge;
@property (readwrite, nonatomic, copy) AFURLSessionDidFinishEventsForBackgroundURLSessionBlock didFinishEventsForBackgroundURLSession AF_API_UNAVAILABLE(macos);
@property (readwrite, nonatomic, copy) AFURLSessionTaskWillPerformHTTPRedirectionBlock taskWillPerformHTTPRedirection;
@property (readwrite, nonatomic, copy) AFURLSessionTaskAuthenticationChallengeBlock authenticationChallengeHandler;
@property (readwrite, nonatomic, copy) AFURLSessionTaskNeedNewBodyStreamBlock taskNeedNewBodyStream;
@property (readwrite, nonatomic, copy) AFURLSessionTaskDidSendBodyDataBlock taskDidSendBodyData;
@property (readwrite, nonatomic, copy) AFURLSessionTaskDidCompleteBlock taskDidComplete;
#if AF_CAN_INCLUDE_SESSION_TASK_METRICS
@property (readwrite, nonatomic, copy) AFURLSessionTaskDidFinishCollectingMetricsBlock taskDidFinishCollectingMetrics AF_API_AVAILABLE(ios(10), macosx(10.12), watchos(3), tvos(10));
#endif
@property (readwrite, nonatomic, copy) AFURLSessionDataTaskDidReceiveResponseBlock dataTaskDidReceiveResponse;
@property (readwrite, nonatomic, copy) AFURLSessionDataTaskDidBecomeDownloadTaskBlock dataTaskDidBecomeDownloadTask;
@property (readwrite, nonatomic, copy) AFURLSessionDataTaskDidReceiveDataBlock dataTaskDidReceiveData;
@property (readwrite, nonatomic, copy) AFURLSessionDataTaskWillCacheResponseBlock dataTaskWillCacheResponse;
@property (readwrite, nonatomic, copy) AFURLSessionDownloadTaskDidFinishDownloadingBlock downloadTaskDidFinishDownloading;
@property (readwrite, nonatomic, copy) AFURLSessionDownloadTaskDidWriteDataBlock downloadTaskDidWriteData;
@property (readwrite, nonatomic, copy) AFURLSessionDownloadTaskDidResumeBlock downloadTaskDidResume;
@end

@implementation AFURLSessionManager

- (instancetype)init {
    return [self initWithSessionConfiguration:nil];
}

/**
*/
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    self = [super init];
    if (!self) {
        return nil;
    }

    if (!configuration) {
        //默认的配置对象，持久化存储缓存，证书，cookie。
        configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    }

    self.sessionConfiguration = configuration;
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;

     //响应转码：默认为 json 数据转码
    self.responseSerializer = [AFJSONResponseSerializer serializer];

    self.securityPolicy = [AFSecurityPolicy defaultPolicy];//设置默认安全策略

#if !TARGET_OS_WATCH
    self.reachabilityManager = [AFNetworkReachabilityManager sharedManager];//网络监控
#endif

    // 设置存储NSURL task与AFURLSessionManagerTaskDelegate的词典（重点，在AFNet中，每一个task都会被匹配一个AFURLSessionManagerTaskDelegate 来做task的delegate事件处理） ===============
    self.mutableTaskDelegatesKeyedByTaskIdentifier = [[NSMutableDictionary alloc] init];

    //  设置AFURLSessionManagerTaskDelegate 词典的锁，确保词典在多线程访问时的线程安全
    self.lock = [[NSLock alloc] init];
    self.lock.name = AFURLSessionManagerLockName;

      // 置空task关联的代理 ；用来异步的获取当前session的所有未完成的task。
    //为了防止后台回来，重新初始化这个session，一些之前的后台请求任务，导致程序的crash
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for (NSURLSessionDataTask *task in dataTasks) {
            [self addDelegateForDataTask:task uploadProgress:nil downloadProgress:nil completionHandler:nil];
        }

        for (NSURLSessionUploadTask *uploadTask in uploadTasks) {
            [self addDelegateForUploadTask:uploadTask progress:nil completionHandler:nil];
        }

        for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
            [self addDelegateForDownloadTask:downloadTask progress:nil destination:nil completionHandler:nil];
        }
    }];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (NSURLSession *)session {
    @synchronized (self) {
        if (!_session) {
            _session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration delegate:self delegateQueue:self.operationQueue];
        }
    }
    return _session;
}

#pragma mark -


- (NSString *)taskDescriptionForSessionTasks {
    return [NSString stringWithFormat:@"%p", self];
}

- (void)taskDidResume:(NSNotification *)notification {
    NSURLSessionTask *task = notification.object;
    if ([task respondsToSelector:@selector(taskDescription)]) {
        if ([task.taskDescription isEqualToString:self.taskDescriptionForSessionTasks]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingTaskDidResumeNotification object:task];
            });
        }
    }
}

- (void)taskDidSuspend:(NSNotification *)notification {
    NSURLSessionTask *task = notification.object;
    if ([task respondsToSelector:@selector(taskDescription)]) {
        if ([task.taskDescription isEqualToString:self.taskDescriptionForSessionTasks]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingTaskDidSuspendNotification object:task];
            });
        }
    }
}

#pragma mark -

/** 可变字典 mutableTaskDelegatesKeyedByTaskIdentifier
 * key   :  NSURLSessionTask.taskIdentifier
 * value :  AFURLSessionManagerTaskDelegate
 *
 * 可变字典不是线程安全的，存取键值时，需要加锁
 */

- (AFURLSessionManagerTaskDelegate *)delegateForTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);
    AFURLSessionManagerTaskDelegate *delegate = nil;
    [self.lock lock];
    delegate = self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)];
    [self.lock unlock];
    return delegate;
}

/** 将 AF代理和task建立映射 */
- (void)setDelegate:(AFURLSessionManagerTaskDelegate *)delegate forTask:(NSURLSessionTask *)task{
    NSParameterAssert(task);
    NSParameterAssert(delegate);
    [self.lock lock];
    //taskIdentifier 由所属会话分配且唯一的任务标识符，
    self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)] = delegate;
    [self addNotificationObserverForTask:task];//添加task开始和暂停的通知
    [self.lock unlock];
}

/** 总结一下:
1）这个方法，生成了一个AFURLSessionManagerTaskDelegate,这个其实就是AF的自定义代理。我们请求传来的参数，都赋值给这个AF的代理了。
2）delegate.manager = self;代理把AFURLSessionManager这个类作为属性了,我们可以看到：
   @property (nonatomic, weak) AFURLSessionManager *manager;
   这个属性是弱引用的，所以不会存在循环引用的问题。
3）我们调用了[self setDelegate:delegate forTask:dataTask];
*/
- (void)addDelegateForDataTask:(NSURLSessionDataTask *)dataTask
                uploadProgress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
              downloadProgress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock
             completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler{
    
    AFURLSessionManagerTaskDelegate *delegate = [[AFURLSessionManagerTaskDelegate alloc] initWithTask:dataTask];
    delegate.manager = self;// AFURLSessionManagerTaskDelegate与AFURLSessionManager建立相互关系
    delegate.completionHandler = completionHandler;

    //这个taskDescriptionForSessionTasks用来发送开始和挂起通知的时候会用到,就是用这个值来 Post 通知，来两者对应
    //任务描述：值为 session 的内存地址
    dataTask.taskDescription = self.taskDescriptionForSessionTasks;
    [self setDelegate:delegate forTask:dataTask]; /** 将 AF代理和task建立映射 */
    
    // 设置AF delegate的上传进度，下载进度块。
    delegate.uploadProgressBlock = uploadProgressBlock;
    delegate.downloadProgressBlock = downloadProgressBlock;
}

- (void)addDelegateForUploadTask:(NSURLSessionUploadTask *)uploadTask
                        progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock
               completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler{
    AFURLSessionManagerTaskDelegate *delegate = [[AFURLSessionManagerTaskDelegate alloc] initWithTask:uploadTask];
    delegate.manager = self;
    delegate.completionHandler = completionHandler;
    uploadTask.taskDescription = self.taskDescriptionForSessionTasks;
    [self setDelegate:delegate forTask:uploadTask];
    delegate.uploadProgressBlock = uploadProgressBlock;
}

- (void)addDelegateForDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                          progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                       destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                 completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler{
    AFURLSessionManagerTaskDelegate *delegate = [[AFURLSessionManagerTaskDelegate alloc] initWithTask:downloadTask];
    delegate.manager = self;
    delegate.completionHandler = completionHandler;

    if (destination) {
        delegate.downloadTaskDidFinishDownloading = ^NSURL * (NSURLSession * __unused session, NSURLSessionDownloadTask *task, NSURL *location) {
            return destination(location, task.response);
        };
    }

    downloadTask.taskDescription = self.taskDescriptionForSessionTasks;
    [self setDelegate:delegate forTask:downloadTask];
    delegate.downloadProgressBlock = downloadProgressBlock;
}

///把这个AF的代理和task的绑定解除了，并且移除了相关的progress和通知：
- (void)removeDelegateForTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);
    [self.lock lock];
    [self removeNotificationObserverForTask:task];
    [self.mutableTaskDelegatesKeyedByTaskIdentifier removeObjectForKey:@(task.taskIdentifier)];
    [self.lock unlock];
}

#pragma mark -

/** 异步的获取当前session的所有未完成的 task
 * 在初始化中调用这个方法应该里面一个task都不会有。那么为什么要这么做呢？
 * 这是为了防止后台回来，重新初始化这个session，一些之前的后台请求任务，导致程序的crash。
 */
- (NSArray *)tasksForKeyPath:(NSString *)keyPath {
    __block NSArray *tasks = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);//信号量值为0
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(dataTasks))]) {
            tasks = dataTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(uploadTasks))]) {
            tasks = uploadTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(downloadTasks))]) {
            tasks = downloadTasks;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(tasks))]) {
            tasks = [@[dataTasks, uploadTasks, downloadTasks] valueForKeyPath:@"@unionOfArrays.self"];//数组合并
        }
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return tasks;
}

- (NSArray *)tasks {
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

- (NSArray *)dataTasks {
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

- (NSArray *)uploadTasks {
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

- (NSArray *)downloadTasks {
    return [self tasksForKeyPath:NSStringFromSelector(_cmd)];
}

#pragma mark -
//当对 session invalidate 后，就不能再创建新的 task 了，

/** 使 NSURLSession 会话无效：可选地取消挂起的任务并可选地重置指定会话。
 * @param cancelPendingTasks  是否取消挂起的任务
 * @param resetSession    是否重置 NSURLSession
 */
- (void)invalidateSessionCancelingTasks:(BOOL)cancelPendingTasks resetSession:(BOOL)resetSession {
    if (cancelPendingTasks) {
        [self.session invalidateAndCancel];//直接取消所有正在执行的 task。
    } else {
        //会等到正在执行的 task 执行完成，调用完所有回调或 delegate 后，释放对 delegate 的强引用
        [self.session finishTasksAndInvalidate];
    }
    if (resetSession) {
        self.session = nil;
    }
}

#pragma mark -

- (void)setResponseSerializer:(id <AFURLResponseSerialization>)responseSerializer {
    NSParameterAssert(responseSerializer);
    _responseSerializer = responseSerializer;
}

#pragma mark -
///网络任务 监听 启动 和 暂停
- (void)addNotificationObserverForTask:(NSURLSessionTask *)task {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidResume:) name:AFNSURLSessionTaskDidResumeNotification object:task];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidSuspend:) name:AFNSURLSessionTaskDidSuspendNotification object:task];
}

- (void)removeNotificationObserverForTask:(NSURLSessionTask *)task {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNSURLSessionTaskDidSuspendNotification object:task];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNSURLSessionTaskDidResumeNotification object:task];
}

#pragma mark - 任务的创建

/** 为什么我们不直接去调用 [self.session dataTaskWithRequest:request];
 * 这是为了适配iOS8的以下，创建session的时候，偶发的情况会出现session的属性 taskIdentifier这个值不唯一，
 * 这个 taskIdentifier 作为映射的key,必须是唯一的。
 * 具体原因应该是NSURLSession内部去生成task的时候是用多线程并发去执行的。
 * 只需要在iOS8以下同步串行的去生成task就可以防止这一问题发生（如果还是不理解同步串行的原因，可以看看注释）。
*/
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                               uploadProgress:(nullable void (^)(NSProgress *uploadProgress)) uploadProgressBlock
                             downloadProgress:(nullable void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                            completionHandler:(nullable void (^)(NSURLResponse *response, id _Nullable responseObject,  NSError * _Nullable error))completionHandler {

    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
    [self addDelegateForDataTask:dataTask uploadProgress:uploadProgressBlock downloadProgress:downloadProgressBlock completionHandler:completionHandler];
    return dataTask; //到这里我们整个对task的处理就完成了。
}

//上传任务
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromFile:(NSURL *)fileURL
                                         progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock
                                completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler{
    NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithRequest:request fromFile:fileURL];
    
    if (uploadTask) {
        [self addDelegateForUploadTask:uploadTask progress:uploadProgressBlock completionHandler:completionHandler];
    }
    return uploadTask;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request
                                         fromData:(NSData *)bodyData
                                         progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock
                                completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler{
    NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithRequest:request fromData:bodyData];
    [self addDelegateForUploadTask:uploadTask progress:uploadProgressBlock completionHandler:completionHandler];
    return uploadTask;
}

- (NSURLSessionUploadTask *)uploadTaskWithStreamedRequest:(NSURLRequest *)request
                                                 progress:(void (^)(NSProgress *uploadProgress)) uploadProgressBlock
                                        completionHandler:(void (^)(NSURLResponse *response, id responseObject, NSError *error))completionHandler{
    NSURLSessionUploadTask *uploadTask = [self.session uploadTaskWithStreamedRequest:request];
    [self addDelegateForUploadTask:uploadTask progress:uploadProgressBlock completionHandler:completionHandler];
    return uploadTask;
}

//下载任务
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                             progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                                          destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                    completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler{
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:request];
    [self addDelegateForDownloadTask:downloadTask progress:downloadProgressBlock destination:destination completionHandler:completionHandler];
    return downloadTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithResumeData:(NSData *)resumeData
                                                progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                                             destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                       completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
{
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithResumeData:resumeData];
    [self addDelegateForDownloadTask:downloadTask progress:downloadProgressBlock destination:destination completionHandler:completionHandler];
    return downloadTask;
}

#pragma mark -

//获取任务的上传进度
- (NSProgress *)uploadProgressForTask:(NSURLSessionTask *)task {
    return [[self delegateForTask:task] uploadProgress];
}

//获取任务的下载进度
- (NSProgress *)downloadProgressForTask:(NSURLSessionTask *)task {
    return [[self delegateForTask:task] downloadProgress];
}

#pragma mark - 设置一些回调 Block

/** NSURLSession 无效时执行的Block
 *@note 在 NSURLSessionDelegate 的 -URLSession:didBecomeInvalidWithError: 方法中调用
 */
- (void)setSessionDidBecomeInvalidBlock:(void (^)(NSURLSession *session, NSError *error))block {
    self.sessionDidBecomeInvalid = block;
}

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
- (void)setSessionDidReceiveAuthenticationChallengeBlock:(NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block {
    self.sessionDidReceiveAuthenticationChallenge = block;
}

#if !TARGET_OS_OSX
//设置后台的回调
- (void)setDidFinishEventsForBackgroundURLSessionBlock:(void (^)(NSURLSession *session))block {
    self.didFinishEventsForBackgroundURLSession = block;
}
#endif


/** 当任务需要一个新的 BodyStream 发送到远程服务器时要执行的Block，
 * @note 在 NSURLSessionTaskDelegate 的 -URLSession:task:needNewBodyStream: 方法中调用
 */
- (void)setTaskNeedNewBodyStreamBlock:(NSInputStream * (^)(NSURLSession *session, NSURLSessionTask *task))block {
    self.taskNeedNewBodyStream = block;
}

/** 当 HTTP 请求试图重定向到另一个URL时要执行的Block，
 * @note 在 NSURLSessionTaskDelegate 的 -URLSession:willPerformHTTPRedirection:newRequest:completionHandler: 方法中调用
 */
- (void)setTaskWillPerformHTTPRedirectionBlock:(NSURLRequest * (^)(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request))block {
    self.taskWillPerformHTTPRedirection = block;
}

/** 设置一个定期执行的Block来监测上传进度
 * @note 在 NSURLSessionTaskDelegate 的 -URLSession:task:didSendBodyData:totalBytesSent:totalbytesexpectedend: 方法中调用
 * @param block 当不确定的字节数被上传到服务器时多次调用，并将在主线程上执行；
 */
- (void)setTaskDidSendBodyDataBlock:(void (^)(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))block {
    self.taskDidSendBodyData = block;
}

/**任务完成时要执行的Block，
 * @note 在 NSURLSessionTaskDelegate 的 -URLSession:task:didCompleteWithError: 方法中调用
 */
- (void)setTaskDidCompleteBlock:(void (^)(NSURLSession *session, NSURLSessionTask *task, NSError *error))block {
    self.taskDidComplete = block;
}

#if AF_CAN_INCLUDE_SESSION_TASK_METRICS
/** 当特定任务相关的 metrics 完成时要执行的Block
 * @note 在 NSURLSessionTaskDelegate 的 -URLSession:task:didFinishCollectingMetrics: 方法中调用
*/
- (void)setTaskDidFinishCollectingMetricsBlock:(void (^)(NSURLSession * _Nonnull, NSURLSessionTask * _Nonnull, NSURLSessionTaskMetrics * _Nullable))block AF_API_AVAILABLE(ios(10), macosx(10.12), watchos(3), tvos(10)) {
    self.taskDidFinishCollectingMetrics = block;
}
#endif

#pragma mark -  设置 NSURLSessionDataDelegate 回调

/** 接收到响应数据时要执行的Block
 * @note 在 NSURLSessionDataDelegate 的 -URLSession:dataTask:didReceiveResponse:completionHandler: 方法中调用
*/
- (void)setDataTaskDidReceiveResponseBlock:(NSURLSessionResponseDisposition (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response))block {
    self.dataTaskDidReceiveResponse = block;
}

/** dataTask 变成 downloadTask 时执行的Block
 * @note 在 NSURLSessionDataDelegate 的 -URLSession:dataTask:didBecomeDownloadTask: 方法中调用
 */
- (void)setDataTaskDidBecomeDownloadTaskBlock:(void (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLSessionDownloadTask *downloadTask))block {
    self.dataTaskDidBecomeDownloadTask = block;
}

/** 接收到数据时要执行的Block
 * @note 在 NSURLSessionDataDelegate 的 -URLSession:dataTask:didReceiveData: 方法中调用
 * @param block 从服务器下载数据时被多次调用的Block ，将在 AFURLSessionManager.operationQueue 执行。
 */
- (void)setDataTaskDidReceiveDataBlock:(void (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data))block {
    self.dataTaskDidReceiveData = block;
}

/** 用于确定 dataTask 缓存行为的Block
 * @note 在 NSURLSessionDataDelegate 的 -URLSession:dataTask:willCacheResponse:completionHandler: 方法中调用
 */
- (void)setDataTaskWillCacheResponseBlock:(NSCachedURLResponse * (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSCachedURLResponse *proposedResponse))block {
    self.dataTaskWillCacheResponse = block;
}

#pragma mark - 设置 NSURLSessionDownloadDelegate 回调

/** downloadTask 完成下载后执行的Block
 * @note 在 NSURLSessionDownloadDelegate 的 -URLSession:downloadTask:didFinishDownloadingToURL: 方法中调用
 * @note 如果 fileManager 将临时文件移动到目的地时遇到错误，将发送通知 AFURLSessionDownloadTaskDidFailToMoveFileNotification ，字典 userInfo 包含下载任务，以及错误信息。
 */
- (void)setDownloadTaskDidFinishDownloadingBlock:(NSURL * (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location))block {
    self.downloadTaskDidFinishDownloading = block;
}

/** 一个定期执行的Block 用于监测下载进度
 * @note 在 NSURLSessionDownloadDelegate 的 -URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite: 方法中调用
 * @param block 从服务器下载数据时被多次调用的Block ，将在 AFURLSessionManager.operationQueue 执行。
*/
- (void)setDownloadTaskDidWriteDataBlock:(void (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite))block {
    self.downloadTaskDidWriteData = block;
}

/** 中断的下载任务被恢复时要执行的Block
 * @note 在 NSURLSessionDownloadDelegate 的 -URLSession:downloadTask:didResumeAtOffset:expectedTotalBytes: 方法中调用
*/
- (void)setDownloadTaskDidResumeBlock:(void (^)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t fileOffset, int64_t expectedTotalBytes))block {
    self.downloadTaskDidResume = block;
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, session: %@, operationQueue: %@>", NSStringFromClass([self class]), self, self.session, self.operationQueue];
}

//能否响应一些方法
- (BOOL)respondsToSelector:(SEL)selector {
    //复写了selector的方法，这几个方法是在本类有实现的，但是如果外面的Block没赋值的话，则返回NO，相当于没有实现！
    if (selector == @selector(URLSession:didReceiveChallenge:completionHandler:)) {
        return self.sessionDidReceiveAuthenticationChallenge != nil;
    } else if (selector == @selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)) {
        return self.taskWillPerformHTTPRedirection != nil;
    } else if (selector == @selector(URLSession:dataTask:didReceiveResponse:completionHandler:)) {
        return self.dataTaskDidReceiveResponse != nil;
    } else if (selector == @selector(URLSession:dataTask:willCacheResponse:completionHandler:)) {
        return self.dataTaskWillCacheResponse != nil;
    }
#if !TARGET_OS_OSX
    else if (selector == @selector(URLSessionDidFinishEventsForBackgroundURLSession:)) {
        return self.didFinishEventsForBackgroundURLSession != nil;
    }
#endif
    //这样如果没实现这些我们自定义的Block也不会去回调这些代理。因为本身某些代理，只执行了这些自定义的Block，如果Block都没有赋值，那我们调用代理也没有任何意义。
    return [[self class] instancesRespondToSelector:selector];
}

#pragma mark - NSURLSessionDelegate

/*当前这个session已经失效时，该代理方法被调用。(当对 session 对象执行了 invalidate 的相关方法后，session失效
)
finishTasksAndInvalidate会等到正在执行的 task 执行完成，调用完所有回调或 delegate 后，释放对 delegate 的强引用
invalidateAndCancel    直接取消所有正在执行的 task。
 */
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    if (self.sessionDidBecomeInvalid) {
        self.sessionDidBecomeInvalid(session, error);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:AFURLSessionDidInvalidateNotification object:session];
}

/* NSURLProtectionSpace类的 authenticationMethod 属性则指明了服务端的验证方式，可能的值包括 :
 NSURLAuthenticationMethodDefault
 NSURLAuthenticationMethodHTTPBasic // 基本的 HTTP 验证，通过 NSURLCredential 对象提供用户名和密码。
 
 NSURLAuthenticationMethodHTTPDigest // 类似于基本的 HTTP 验证，摘要会自动生成，同样通过 NSURLCredential 对象提供用户名和密码。

 NSURLAuthenticationMethodHTMLForm // 不会用于 URL Loading System，在通过 web 表单验证时可能用到。

 NSURLAuthenticationMethodNTLM
 NSURLAuthenticationMethodNegotiate
 NSURLAuthenticationMethodClientCertificate // 验证客户端的证书
 NSURLAuthenticationMethodServerTrust // 指明客户端要验证服务端提供的证书
 */
/* 系统处理验证的方式：
 NSURLSessionAuthChallengePerformDefaultHandling // 相当于未执行代理方法，使用默认的处理方式，不使用参数 credential

 NSURLSessionAuthChallengeUseCredential // 指明通过另一个参数 credential 提供证书
 NSURLSessionAuthChallengeCancelAuthenticationChallenge // 取消验证，不使用参数 credential
 NSURLSessionAuthChallengeRejectProtectionSpace //拒绝该 protectionSpace 的验证，不使用参数 credential
 */

/* *当在 SSL 握手阶段，如果服务器要求验证客户端身份或向客户端提供其证书用于验证时，则会调用 此代理方法
 
 服务器接收到客户端请求时，有时候需要先验证客户端是否为正常用户，再决定是够返回真实数据。这种情况称之为服务端要求客户端接收挑战
 
 NSURLAuthenticationChallenge *challenge 它封装了服务端对客户端的验证请求，
    根据它的 protectionSpace 属性的 authenticationMethod 可以知道服务端要通过哪种方式验证客户端或是要求客户端验证服务端的证书
 
 当 authenticationMethod 的值为：
 NSURLAuthenticationMethodNTLM、
 NSURLAuthenticationMethodNegotiate、
 NSURLAuthenticationMethodClientCertificate和
 NSURLAuthenticationMethodServerTrust时，
 系统会先尝试调用 session 级的处理方法，若 session 级未实现，则尝试调用 task 级的处理方法，而其他情况则是直接调用 task 级的处理方法，无论 session 级方法是否实现。
 
 在NSURLSession的代理方法中执行相应的逻辑后，需调用代理方法的 block 参数 completionHandler，来通知系统如何处理验证。该 block 需要传入两个参数，NSURLSessionAuthChallengeDisposition类型的 disposition，说明处理的方式，另一个参数是对应的NSURLCredential对象。
 
 NSURLCredential 当 disposition 的值为 NSURLSessionAuthChallengeUseCredential时，需要提供一个 NSURLCredential 对象。可以创建3种类型的 Credential：
 （1）、当 protectionSpace 的 authenticationMethod 的值为 NSURLAuthenticationMethodHTTPBasic 或 NSURLAuthenticationMethodHTTPDigest 时
 + credentialWithUser:password:persistence:
 - initWithUser:password:persistence:
 （2）、当 protectionSpace 的 authenticationMethod 的值为NSURLAuthenticationMethodClientCertificate时
 + credentialWithIdentity:certificates:persistence:
 - initWithIdentity:certificates:persistence:
 （3）、当 protectionSpace 的 authenticationMethod 的值为 NSURLAuthenticationMethodServerTrust 时
 + credentialForTrust:
 - initWithTrust:
 */
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    NSAssert(self.sessionDidReceiveAuthenticationChallenge != nil, @"`respondsToSelector:` implementation forces `URLSession:didReceiveChallenge:completionHandler:` to be called only if `self.sessionDidReceiveAuthenticationChallenge` is not nil");

    NSURLCredential *credential = nil;
    NSURLSessionAuthChallengeDisposition disposition = self.sessionDidReceiveAuthenticationChallenge(session, challenge, &credential);

    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

#pragma mark - NSURLSessionTaskDelegate
/* 这个方法是在服务器去重定向的时候，才会被调用
当响应为重定向到其他请求时，系统会调用此代理方法；在方法中要执行 block 参数 completionHandler，可向其传入重定向的新的NSURLRequest对象，那么会正常执行重定向请求，也可以传入 nil，则不执行重定向请求并以当前响应体作为重定向后的响应。
*/
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    NSURLRequest *redirectRequest = request;

    if (self.taskWillPerformHTTPRedirection) {
        redirectRequest = self.taskWillPerformHTTPRedirection(session, task, response, request);
    }

    if (completionHandler) {
        completionHandler(redirectRequest);
    }
}

/* 当在 SSL 握手阶段，如果服务器要求验证客户端身份或向客户端提供其证书用于验证时，则会调用
* challenge（服务端对客户端的验证请求）的 protectionSpace 属性的 authenticationMethod 可以知道服务端要通过哪种方式验证客户端或是要求客户端验证服务端的证书
当 authenticationMethod 的值为：
*/
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    BOOL evaluateServerTrust = NO;
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;

    if (self.authenticationChallengeHandler) {
        id result = self.authenticationChallengeHandler(session, task, challenge, completionHandler);
        if (result == nil) {
            return;
        } else if ([result isKindOfClass:NSError.class]) {
            objc_setAssociatedObject(task, AuthenticationChallengeErrorKey, result, OBJC_ASSOCIATION_RETAIN);
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        } else if ([result isKindOfClass:NSURLCredential.class]) {
            credential = result;
            disposition = NSURLSessionAuthChallengeUseCredential;
        } else if ([result isKindOfClass:NSNumber.class]) {
            disposition = [result integerValue];
            NSAssert(disposition == NSURLSessionAuthChallengePerformDefaultHandling || disposition == NSURLSessionAuthChallengeCancelAuthenticationChallenge || disposition == NSURLSessionAuthChallengeRejectProtectionSpace, @"");
            evaluateServerTrust = disposition == NSURLSessionAuthChallengePerformDefaultHandling && [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
        } else {
            @throw [NSException exceptionWithName:@"Invalid Return Value" reason:@"The return value from the authentication challenge handler must be nil, an NSError, an NSURLCredential or an NSNumber." userInfo:nil];
        }
    } else {
        evaluateServerTrust = [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
    }

    if (evaluateServerTrust) {
        if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
            disposition = NSURLSessionAuthChallengeUseCredential;
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        } else {
            objc_setAssociatedObject(task, AuthenticationChallengeErrorKey,
                                     [self serverTrustErrorForServerTrust:challenge.protectionSpace.serverTrust url:task.currentRequest.URL],
                                     OBJC_ASSOCIATION_RETAIN);
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }

    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

- (nonnull NSError *)serverTrustErrorForServerTrust:(nullable SecTrustRef)serverTrust url:(nullable NSURL *)url
{
    NSBundle *CFNetworkBundle = [NSBundle bundleWithIdentifier:@"com.apple.CFNetwork"];
    NSString *defaultValue = @"The certificate for this server is invalid. You might be connecting to a server that is pretending to be “%@” which could put your confidential information at risk.";
    NSString *descriptionFormat = NSLocalizedStringWithDefaultValue(@"Err-1202.w", nil, CFNetworkBundle, defaultValue, @"") ?: defaultValue;
    NSString *localizedDescription = [descriptionFormat componentsSeparatedByString:@"%@"].count <= 2 ? [NSString localizedStringWithFormat:descriptionFormat, url.host] : descriptionFormat;
    NSMutableDictionary *userInfo = [@{
        NSLocalizedDescriptionKey: localizedDescription
    } mutableCopy];

    if (serverTrust) {
        userInfo[NSURLErrorFailingURLPeerTrustErrorKey] = (__bridge id)serverTrust;
    }

    if (url) {
        userInfo[NSURLErrorFailingURLErrorKey] = url;

        if (url.absoluteString) {
            userInfo[NSURLErrorFailingURLStringErrorKey] = url.absoluteString;
        }
    }

    return [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorServerCertificateUntrusted userInfo:userInfo];
}

/*
当使用 - uploadTaskWithStreamedRequest: 方法创建的 task 发起请求时，必须实现此代理方法，以提供请求需要的 stream。因为从输入流读数据是不可逆的，所以在上传失败时，可能会重新调用该方法读取流。在方法中执行 block completionHandler 参数，向其传入 NSInputStream 对象。
*/
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
    NSInputStream *inputStream = nil;

    if (self.taskNeedNewBodyStream) {
        inputStream = self.taskNeedNewBodyStream(session, task);
    } else if (task.originalRequest.HTTPBodyStream && [task.originalRequest.HTTPBodyStream conformsToProtocol:@protocol(NSCopying)]) {
        inputStream = [task.originalRequest.HTTPBodyStream copy];
    }

    if (completionHandler) {
        completionHandler(inputStream);
    }
}

///当执行 upload task 时，系统会定期的调用此代理方法，报告上传请求体的进度。
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{

    int64_t totalUnitCount = totalBytesExpectedToSend;
    if (totalUnitCount == NSURLSessionTransferSizeUnknown) {
        NSString *contentLength = [task.originalRequest valueForHTTPHeaderField:@"Content-Length"];
        if (contentLength) {
            totalUnitCount = (int64_t) [contentLength longLongValue];
        }
    }
    
    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:task];
    
    if (delegate) {
        [delegate URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
    }

    if (self.taskDidSendBodyData) {
        self.taskDidSendBodyData(session, task, bytesSent, totalBytesSent, totalUnitCount);
    }
}

/* 当 task 执行完成后，会调用此代理方法：
如果 task 失败，error 参数为包含具体信息的NSError对象，若成功，error 则为 nil。
对于 HTTP 协议来说：服务器返回的响应 code 为失败时，不属于 task 执行失败的情况，以 task 的角度看，这个请求 task 是成功执行的，data 中会包含返回的内容
当 download task 失败时，在 error 对象的 userInfo 中可以根据 key:NSURLSessionDownloadTaskResumeData获得已下载的数据，之后可用于创建从断点处继续下载的 task

*/
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    //根据task去取我们一开始创建绑定的delegate
    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:task];

    // delegate may be nil when completing a task in the background
    if (delegate) { //把代理转发给我们绑定的delegate
        [delegate URLSession:session task:task didCompleteWithError:error];

        [self removeDelegateForTask:task]; //转发完移除delegate
    }

    if (self.taskDidComplete) {//自定义Block回调
        self.taskDidComplete(session, task, error);
    }
}

#if AF_CAN_INCLUDE_SESSION_TASK_METRICS
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics AF_API_AVAILABLE(ios(10), macosx(10.12), watchos(3), tvos(10))
{
    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:task];
    // Metrics may fire after URLSession:task:didCompleteWithError: is called, delegate may be nil
    if (delegate) {
        [delegate URLSession:session task:task didFinishCollectingMetrics:metrics];
    }

    if (self.taskDidFinishCollectingMetrics) {
        self.taskDidFinishCollectingMetrics(session, task, metrics);
    }
}
#endif

#pragma mark - NSURLSessionDataDelegate

/*
 NSURLSessionResponseCancel 该task会被取消
 NSURLSessionResponseAllow  该task正常进行
 NSURLSessionResponseBecomeDownload 会调用
 NSURLSessionResponseBecomeStream 转成一个StreamTask
 */
/*
 当 data task 收到响应时，会调用此代理方法；
 在方法中要执行 block 参数 completionHandler，向其传入 NSURLSessionResponseDisposition 枚举类型参数，指明继续正常返回响应体，还是取消请求，或者将 task 转变为 download task。
 传入 NSURLSessionResponseBecomeDownload，将 task 转换为 download task 后，会调用代理方法 URLSession:dataTask:didBecomeDownloadTask:

 如果你的request中包含的content-type支持 multipart/x-mixed-replace 时，服务器会将数据分片传回来，而且每次传回来的数据会覆盖之前的数据。每次返回新的数据时，session都会调用该函数，你应该在这个函数中合理地处理先前的数据，否则会被新数据覆盖。如果你没有提供该方法的实现，那么session将会继续任务，也就是说会覆盖之前的数据。
 */
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    //设置默认为继续进行
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseAllow;

    if (self.dataTaskDidReceiveResponse) {//自定义去设置
        disposition = self.dataTaskDidReceiveResponse(session, dataTask, response);
    }

    if (completionHandler) {
        completionHandler(disposition);
    }
}

/*
当 download task 收到响应时，会调用此代理方法；
在方法中要执行 block 参数 completionHandler，向其传入 NSURLSessionResponseDisposition 枚举类型参数，指明继续正常返回响应体，还是取消请求
*/
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    //因为转变了task，所以要对task做一个重新绑定
    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:dataTask];
    if (delegate) {
        [self removeDelegateForTask:dataTask];
        [self setDelegate:delegate forTask:downloadTask];
    }

    if (self.dataTaskDidBecomeDownloadTask) {
        self.dataTaskDidBecomeDownloadTask(session, dataTask, downloadTask);
    }
}

/*
当从服务端接收数据时，系统会调用相应的代理方法，定期提供已接收到的数据，
对于 data task，会调用方法URLSession:dataTask:didReceiveData:，
而 download task 则会调用方法
URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:
*/
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{

    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:dataTask];
    [delegate URLSession:session dataTask:dataTask didReceiveData:data];

    if (self.dataTaskDidReceiveData) {
        self.dataTaskDidReceiveData(session, dataTask, data);
    }
}

/*
对于 data task 或 upload task，在收到所有数据后，可能会调用此代理方法：提供给应用决定是否缓存响应的机会。
方法中要执行 block 参数 completionHandler，如果缓存则传入一个 NSCachedURLResponse 对象，若不想缓存可传入 nil。
当返回的响应为缓存中的时候，则不调用该方法。
*/
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
    NSCachedURLResponse *cachedResponse = proposedResponse;

    if (self.dataTaskWillCacheResponse) {
        cachedResponse = self.dataTaskWillCacheResponse(session, dataTask, proposedResponse);
    }

    if (completionHandler) {
        completionHandler(cachedResponse);
    }
}

#if !TARGET_OS_OSX

/* 后台 session
 
 当挂起的应用执行的后台传输(下载、上传)完成或者发生错误以及需要身份验证时，系统会运行应用并调用应用代理的
 - application:handleEventsForBackgroundURLSession:completionHandler:方法。
 如果传输完成可以执行一些更新界面的操作，如果没有成功，则可以根据 identifier 参数重新创建 background session 继续执行。
 在该方法中应使用实例变量强引用 block 参数 completionHandler，在上述相关操作(如重新关联 session)完成后，系统会调用 session 的代理方法
 URLSessionDidFinishEventsForBackgroundURLSession:，此时在该代理方法中运行之前应用代理维持的 block，以通知系统应用已完成处理工作，要注意的是，该 completionHandler 要在主线程中执行。
*/
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    if (self.didFinishEventsForBackgroundURLSession) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.didFinishEventsForBackgroundURLSession(session);
        });
    }
}
#endif

#pragma mark - NSURLSessionDownloadDelegate

/* 当 download task 成功执行完成后，会执行此代理方法：

这个代理方法是 SURLSessionDownloadDelegate 协议中必须实现的，方法参数传入一个下载文件的临时保存路径，应用需要读取文件的内容或将文件移到其他地方，因为代理方法执行结束后，该路径下的文件会被删除，注意，如果读取文件内容的话，则要在单独的线程中进行，否则可能会造成页面卡死，影响用户体验。
*/
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:downloadTask];
    if (self.downloadTaskDidFinishDownloading) {
        NSURL *fileURL = self.downloadTaskDidFinishDownloading(session, downloadTask, location);
        if (fileURL) {
            delegate.downloadFileURL = fileURL;
            NSError *error = nil;
            
            if (![[NSFileManager defaultManager] moveItemAtURL:location toURL:fileURL error:&error]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:AFURLSessionDownloadTaskDidFailToMoveFileNotification object:downloadTask userInfo:error.userInfo];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:AFURLSessionDownloadTaskDidMoveFileSuccessfullyNotification object:downloadTask userInfo:nil];
            }

            return;
        }
    }

    if (delegate) {
        [delegate URLSession:session downloadTask:downloadTask didFinishDownloadingToURL:location];
    }
}


/*
 当从服务端接收数据时，系统会调用相应的代理方法，定期提供已接收到的数据，
 对于 data task，会调用方法URLSession:dataTask:didReceiveData:，
 而 download task 则会调用方法
 URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:
 */
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    
    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:downloadTask];
    
    if (delegate) {
        [delegate URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }

    if (self.downloadTaskDidWriteData) {
        self.downloadTaskDidWriteData(session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    }
}

/*
当执行以下方法
- downloadTaskWithResumeData:  或
- downloadTaskWithResumeData:completionHandler:
创建的 download task 时，会调用此代理方法
*/
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
    AFURLSessionManagerTaskDelegate *delegate = [self delegateForTask:downloadTask];
    
    if (delegate) {
        [delegate URLSession:session downloadTask:downloadTask didResumeAtOffset:fileOffset expectedTotalBytes:expectedTotalBytes];
    }

    if (self.downloadTaskDidResume) {
        self.downloadTaskDidResume(session, downloadTask, fileOffset, expectedTotalBytes);
    }
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    NSURLSessionConfiguration *configuration = [decoder decodeObjectOfClass:[NSURLSessionConfiguration class] forKey:@"sessionConfiguration"];

    self = [self initWithSessionConfiguration:configuration];
    if (!self) {
        return nil;
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.session.configuration forKey:@"sessionConfiguration"];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithSessionConfiguration:self.session.configuration];
}

@end
