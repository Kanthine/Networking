//
//  URLSessionManager+Block.h
//  Networking
//
//  Created by 苏沫离 on 2020/6/2.
//  Copyright © 2020 苏沫离. All rights reserved.
//


#import "URLSessionManager.h"

@interface URLSessionManager (Block)

/*
 通过创建一个 alloc 发送一个 get 请求
 */
+ (void)getBlockByAlloc;

/*
 通过创建一个 sharedSession 发送一个 get 请求
 */
+ (void)getBlockBySharedSession;

/* 通过 sessionWithConfiguration：创建一个session 发送一个 get 请求
 */
+ (void)getBlockByConfiguration;

/* 通过 sessionWithConfiguration：创建一个session 发送一个 get 请求
 */
+ (void)getBlockByDelegateQueue;

/*
 通过创建一个 sharedSession 发送一个 post 请求
 */
+ (void)postBlockByAlloc;

/*
 通过创建一个 sharedSession 发送一个 post 请求
 */
+ (void)postBlockBySharedSession;

/* 通过 sessionWithConfiguration：创建一个session 发送一个 post 请求
 */
+ (void)postBlockByConfiguration;

/* 通过 sessionWithConfiguration：创建一个session 发送一个 post 请求
 */
+ (void)postBlockByDelegateQueue;


+ (void)postBlockUpload;

+ (void)getBlockDownLoadFile:(nullable void (^)(NSString * _Nonnull filePath))filePath;

@end

/*
 
 初始化方法
 
 
 通过 Block 回调请求到的结果：
 不能使用 [[NSURLSession alloc] init]; 否则无法创建一个 Configuration 导致程序异常终止
 
 响应的执行线程问题：- dataTaskWithRequest: completionHandler:;
 若delegateQueue = nil，则不管session执行的线程为主线程还是子线程，completionHandler中的代码执行线程均为任意选择的子线程；
 若delegateQueue = [NSOperationQueue mainQueue],则不管session执行的线程为主线程还是子线程，则completionHandler中的代码执行线程为主线程中执行；
 若delegateQueue = [[NSOperationQueue alloc]init]，则不管session执行的线程为主线程还是子线程，completionHandler中的代码执行线程均为任意选择的子线程；
 
 */
