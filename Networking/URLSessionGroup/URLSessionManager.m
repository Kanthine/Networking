//
//  URLSessionManager.m
//  Networking
//
//  Created by 苏沫离 on 2020/6/2.
//  Copyright © 2020 苏沫离. All rights reserved.
//


#import "URLSessionManager.h"

#define iTunes_URL @"http://itunes.apple.com/lookup?id=1164001330"

@interface URLSessionManager()

@end


@implementation URLSessionManager

+( URLSessionManager *)shareManager
{
    static URLSessionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      manager = [[URLSessionManager alloc] init];
                      manager.sessionQueue = [[NSOperationQueue alloc] init];
                  });
    
    return manager;
}

#pragma mark - NSURLSessionDelegate

//当对 session 对象执行了 invalidate 的相关方法后，会调用此代理方法。之后 session 会释放对代理对象的强引用。
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error
{
    NSLog(@"%s \n%@ ",__func__,[NSThread currentThread]);
}


//当在 SSL 握手阶段，如果服务器要求验证客户端身份或向客户端提供其证书用于验证时，则会调用 此代理方法
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    NSLog(@"%s \n%@ ",__func__,[NSThread currentThread]);

    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling; // 相当于未执行代理方法，使用默认的处理方式，不使用参数 credential
    
    __block NSURLCredential *credential = nil;
    
    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    
    if (credential) {
        disposition = NSURLSessionAuthChallengeUseCredential;// 指明通过另一个参数 credential 提供证书
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }

}


#pragma mark - NSURLSessionTaskDelegate

/*
 客户端告知服务器端需要HTTP重定向。不现在此代理：默认是按重定向。
 此方法只会在default session或者ephemeral session中调用，而在background session中，session task会自动重定向。
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    NSLog(@"%s \n%@ ",__func__,[NSThread currentThread]);
    completionHandler(request);//必须完成重定向
}

/* 证书处理
 *
 任务已收到请求特定身份验证的挑战。
 如果不实现此代理，将返回默认挑战类型
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    NSLog(@"%s \n%@ ",__func__,[NSThread currentThread]);

    //挑战处理类型为 默认
    /*
     NSURLSessionAuthChallengePerformDefaultHandling：默认方式处理
     NSURLSessionAuthChallengeUseCredential：使用指定的证书
     NSURLSessionAuthChallengeCancelAuthenticationChallenge：取消挑战
     */
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    
    if (credential) {
        disposition = NSURLSessionAuthChallengeUseCredential;
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }    
}

//请求完成(成功|失败)的时候会调用该方法，如果请求失败，则error有值
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    NSLog(@"%s \n%@ ",__func__,[NSThread currentThread]);
}


#pragma mark - NSURLSessionDataDelegate

// 1. 接受到服务器的响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    NSLog(@"%s \n%@ ",__func__,[NSThread currentThread]);

    // 必须设置对响应进行允许处理才会执行后面两个操作。
    completionHandler(NSURLSessionResponseAllow);
}

// 2. 接收到服务器的数据（可能调用多次）
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    NSError *error;
    id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    NSLog(@"%s \n%@ \n %@",__func__,[NSThread currentThread],object);
}


@end
