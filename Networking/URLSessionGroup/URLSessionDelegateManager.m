//
//  URLSessionDelegateManager.m
//  Networking
//
//  Created by 苏沫离 on 2020/6/2.
//  Copyright © 2020 苏沫离. All rights reserved.
//


#import "URLSessionDelegateManager.h"

@implementation URLSessionDelegateManager

#pragma mark - NSURLSessionDelegate

/*当前这个session已经失效时，该代理方法被调用。(当对 session 对象执行了 invalidate 的相关方法后，session失效
 )
 finishTasksAndInvalidate会等到正在执行的 task 执行完成，调用完所有回调或 delegate 后，释放对 delegate 的强引用
 invalidateAndCancel    直接取消所有正在执行的 task。
 */
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error
{
    
}

/* *当在 SSL 握手阶段，如果服务器要求验证客户端身份或向客户端提供其证书用于验证时，则会调用 此代理方法
 服务器接收到客户端请求时，有时候需要先验证客户端是否为正常用户，再决定是够返回真实数据。这种情况称之为服务端要求客户端接收挑战
 */
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    
}

/* 后台 session
 
 当挂起的应用执行的后台传输(下载、上传)完成或者发生错误以及需要身份验证时，系统会运行应用并调用应用代理的
 - application:handleEventsForBackgroundURLSession:completionHandler:方法。
 如果传输完成可以执行一些更新界面的操作，如果没有成功，则可以根据 identifier 参数重新创建 background session 继续执行。
 在该方法中应使用实例变量强引用 block 参数 completionHandler，在上述相关操作(如重新关联 session)完成后，系统会调用 session 的代理方法
 URLSessionDidFinishEventsForBackgroundURLSession:，此时在该代理方法中运行之前应用代理维持的 block，以通知系统应用已完成处理工作，要注意的是，该 completionHandler 要在主线程中执行。
 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    
}

#pragma mark - NSURLSessionTaskDelegate <NSURLSessionDelegate>

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willBeginDelayedRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLSessionDelayedRequestDisposition disposition, NSURLRequest * _Nullable newRequest))completionHandler
{
    
}

- (void)URLSession:(NSURLSession *)session taskIsWaitingForConnectivity:(NSURLSessionTask *)task
{
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    
}

/* 当在 SSL 握手阶段，如果服务器要求验证客户端身份或向客户端提供其证书用于验证时，则会调用
 * challenge（服务端对客户端的验证请求）的 protectionSpace 属性的 authenticationMethod 可以知道服务端要通过哪种方式验证客户端或是要求客户端验证服务端的证书
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream * _Nullable bodyStream))completionHandler
{
    
}

///当执行 upload task 时，系统会定期的调用此代理方法，报告上传请求体的进度。
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
{
    
    
}

/* 当 task 执行完成后，会调用此代理方法：
 如果 task 失败，error 参数为包含具体信息的NSError对象，若成功，error 则为 nil。
 对于 HTTP 协议来说：服务器返回的响应 code 为失败时，不属于 task 执行失败的情况，以 task 的角度看，这个请求 task 是成功执行的，data 中会包含返回的内容
 当 download task 失败时，在 error 对象的 userInfo 中可以根据 key:NSURLSessionDownloadTaskResumeData获得已下载的数据，之后可用于创建从断点处继续下载的 task
 
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    
}

#pragma mark - NSURLSessionDataDelegate <NSURLSessionTaskDelegate>


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    
    
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didBecomeStreamTask:(NSURLSessionStreamTask *)streamTask
{
    
}


/* *当我们获取到数据就会调用，会被反复调用，请求到的数据就在这被拼装完整

 当从服务端接收数据时，系统会调用相应的代理方法，定期提供已接收到的数据，
 对于 data task，会调用方法URLSession:dataTask:didReceiveData:，
 而 download task 则会调用方法
 URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler
{
    
}

#pragma mark - NSURLSessionDownloadDelegate <NSURLSessionTaskDelegate>

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
    
}

#pragma mark - NSURLSessionStreamDelegate<NSURLSessionTaskDelegate>

- (void)URLSession:(NSURLSession *)session readClosedForStreamTask:(NSURLSessionStreamTask *)streamTask
{
    
}


- (void)URLSession:(NSURLSession *)session writeClosedForStreamTask:(NSURLSessionStreamTask *)streamTask
{
    
}

- (void)URLSession:(NSURLSession *)session betterRouteDiscoveredForStreamTask:(NSURLSessionStreamTask *)streamTask
{
    
}


- (void)URLSession:(NSURLSession *)session streamTask:(NSURLSessionStreamTask *)streamTask
didBecomeInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    
}

@end
