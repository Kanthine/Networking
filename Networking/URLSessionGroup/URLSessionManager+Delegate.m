//
//  URLSessionManager+Delegate.m
//  Networking
//
//  Created by 苏沫离 on 2020/6/2.
//  Copyright © 2020 苏沫离. All rights reserved.
//


#import "URLSessionManager+Delegate.h"

@implementation URLSessionManager (Delegate)

+ (void)getDelegateMethod
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:iTunes_URL]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self.shareManager delegateQueue:self.shareManager.sessionQueue];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
}

+ (void)postDelegateMethod
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:iTunes_URL]];
    request.HTTPMethod = @"POST";
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self.shareManager delegateQueue:self.shareManager.sessionQueue];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
}

@end
