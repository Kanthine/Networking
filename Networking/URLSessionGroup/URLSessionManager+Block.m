//
//  URLSessionManager+Block.m
//  Networking
//
//  Created by 苏沫离 on 2020/6/2.
//  Copyright © 2020 苏沫离. All rights reserved.
//


#import "URLSessionManager+Block.h"
#import <UIKit/UIKit.h>

@implementation URLSessionManager (Block)

//Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[NSURLSession dataTaskForRequest:completion:]: unrecognized selector sent to instance 0x170004f80'
+ (void)getBlockByAlloc
{
//    [MBProgressHUD showHUDAddedTo:UIApplication.sharedApplication.keyWindow animated:YES];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:iTunes_URL]];
    NSURLSession *session = [[NSURLSession alloc] init];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
//            [MBProgressHUD hideHUDForView:UIApplication.sharedApplication.keyWindow animated:YES];
        }];
        
        NSLog(@"currentThread : %@",[NSThread currentThread]);
        if (error)
        {
            NSLog(@"请求失败：%@",error);
        }
        else
        {
            NSLog(@"请求成功");
        }
    }];
    [dataTask resume];
}

+ (void)getBlockBySharedSession
{
//    [MBProgressHUD showHUDAddedTo:UIApplication.sharedApplication.keyWindow animated:YES];
    
    //默认是GET请求
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:iTunes_URL]];
    NSURLSession *session = [NSURLSession sharedSession];//获取单列
    
    /*
     注意：该block是在子线程中调用的，如果拿到数据之后要做一些UI刷新操作，那么需要回到主线程刷新
     第一个参数：需要发送的请求对象
     block:当请求结束拿到服务器响应的数据时调用block
     block-NSData:该请求的响应体
     block-NSURLResponse:存放本次请求的响应信息，响应头，真实类型为NSHTTPURLResponse
     block-NSErroe:请求错误信息
     */
    //2.根据NSURLSession对象创建一个Task
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
//            [MBProgressHUD hideHUDForView:UIApplication.sharedApplication.keyWindow animated:YES];
        }];
        
        NSLog(@"currentThread : %@",[NSThread currentThread]);
        if (error)
        {
            NSLog(@"请求失败：%@",error);
        }
        else
        {
            NSLog(@"请求成功");
        }

    }];
    //3.执行Task
    //注意：刚创建出来的task默认是挂起状态的，需要调用该方法来启动任务（执行任务
    [dataTask resume];
}

+ (void)getBlockByConfiguration
{
//    [MBProgressHUD showHUDAddedTo:UIApplication.sharedApplication.keyWindow animated:YES];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:iTunes_URL]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
//            [MBProgressHUD hideHUDForView:UIApplication.sharedApplication.keyWindow animated:YES];
        }];
        NSLog(@"currentThread : %@",[NSThread currentThread]);
        if (error)
        {
            NSLog(@"请求失败：%@",error);
        }
        else
        {
            NSLog(@"请求成功");
        }
    }];
    //3.执行Task
    //注意：刚创建出来的task默认是挂起状态的，需要调用该方法来启动任务（执行任务
    [dataTask resume];
}

+ (void)getBlockByDelegateQueue
{
//    [MBProgressHUD showHUDAddedTo:UIApplication.sharedApplication.keyWindow animated:YES];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:iTunes_URL]];
    
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self.shareManager delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
//            [MBProgressHUD hideHUDForView:UIApplication.sharedApplication.keyWindow animated:YES];
        }];
        NSLog(@"currentThread : %@",[NSThread currentThread]);
        if (error)
        {
            NSLog(@"请求失败：%@",error);
        }
        else
        {
            NSLog(@"请求成功");
        }
    }];
    //3.执行Task
    //注意：刚创建出来的task默认是挂起状态的，需要调用该方法来启动任务（执行任务
    [dataTask resume];
}


/*
 [[NSURLSession alloc] init] 错误的初始化方法，无法配置 configuration 。导致程序闪退
 Terminating app due to uncaught exception 'NSInvalidArgumentException',
 reason: '-[NSURLSession dataTaskForRequest:completion:]: unrecognized selector sent to instance 0x170204540'
  */

+ (void)postBlockByAlloc
{
//    [MBProgressHUD showHUDAddedTo:UIApplication.sharedApplication.keyWindow animated:YES];
    NSURLSession *session = [[NSURLSession alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:iTunes_URL]];
    request.HTTPMethod = @"POST";
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
//            [MBProgressHUD hideHUDForView:UIApplication.sharedApplication.keyWindow animated:YES];
        }];
        NSLog(@"currentThread : %@",[NSThread currentThread]);
        if (error)
        {
            NSLog(@"请求失败：%@",error);
        }
        else
        {
            NSLog(@"请求成功");
        }
    }];
    [dataTask resume];
}

+ (void)postBlockBySharedSession
{
//    [MBProgressHUD showHUDAddedTo:UIApplication.sharedApplication.keyWindow animated:YES];
    NSURLSession *session = [NSURLSession sharedSession];//获取单列
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:iTunes_URL]];
    request.HTTPMethod = @"POST";
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
//            [MBProgressHUD hideHUDForView:UIApplication.sharedApplication.keyWindow animated:YES];
        }];
        NSLog(@"currentThread : %@",[NSThread currentThread]);
        if (error)
        {
            NSLog(@"请求失败：%@",error);
        }
        else
        {
            NSLog(@"请求成功");
        }
    }];
    //3.执行Task
    //注意：刚创建出来的task默认是挂起状态的，需要调用该方法来启动任务（执行任务
    [dataTask resume];
}

/* 通过 sessionWithConfiguration：创建一个session 发送一个 post 请求
 */
+ (void)postBlockByConfiguration
{
//    [MBProgressHUD showHUDAddedTo:UIApplication.sharedApplication.keyWindow animated:YES];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:iTunes_URL]];
    request.HTTPMethod = @"POST";
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
//            [MBProgressHUD hideHUDForView:UIApplication.sharedApplication.keyWindow animated:YES];
        }];
        NSLog(@"currentThread : %@",[NSThread currentThread]);
        if (error)
        {
            NSLog(@"请求失败：%@",error);
        }
        else
        {
            NSLog(@"请求成功");
        }
    }];
    //3.执行Task
    //注意：刚创建出来的task默认是挂起状态的，需要调用该方法来启动任务（执行任务
    [dataTask resume];
}

/* 通过 sessionWithConfiguration：创建一个session 发送一个 post 请求
 */
+ (void)postBlockByDelegateQueue
{
//    [MBProgressHUD showHUDAddedTo:UIApplication.sharedApplication.keyWindow animated:YES];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:queue];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:iTunes_URL]];
    request.HTTPMethod = @"POST";
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
//            [MBProgressHUD hideHUDForView:UIApplication.sharedApplication.keyWindow animated:YES];
        }];
        NSLog(@"currentThread : %@",[NSThread currentThread]);
        if (error)
        {
            NSLog(@"请求失败：%@",error);
        }
        else
        {
            NSLog(@"请求成功");
        }
    }];
    //3.执行Task
    //注意：刚创建出来的task默认是挂起状态的，需要调用该方法来启动任务（执行任务
    [dataTask resume];
}

+ (void)postBlockUpload
{
//    [MBProgressHUD showHUDAddedTo:UIApplication.sharedApplication.keyWindow animated:YES];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:queue];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://long.xn--bttn85k.cn/fancy/userService.do?method=updateFile"]];
    request.HTTPMethod = @"POST";
    [request setValue:@"multipart/form-data;boundary=***" forHTTPHeaderField:@"Content-Type"];
    NSData *imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"my_Back"], 0.5);
    NSMutableData *bodyData = [NSMutableData dataWithData:imageData];
    NSURLSessionUploadTask *dask = [session uploadTaskWithRequest:request fromData:bodyData completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
//            [MBProgressHUD hideHUDForView:UIApplication.sharedApplication.keyWindow animated:YES];
        }];
        NSLog(@"currentThread : %@",[NSThread currentThread]);
        if (error)
        {
            NSLog(@"请求失败：%@",error);
        }
        else
        {
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            //解析拿到的响应数据
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            NSLog(@"请求成功：%@",dict);
        }
    }];
    [dask resume];
}


+ (void)getBlockDownLoadFile:(nullable void (^)(NSString * _Nonnull filePath))filePath
{
//    [MBProgressHUD showHUDAddedTo:UIApplication.sharedApplication.keyWindow animated:YES];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSString *imagePath = @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1528867244313&di=904a1b5eb7db534ea15ce4c266bfa1c4&imgtype=0&src=http%3A%2F%2Fpic.58pic.com%2F58pic%2F15%2F36%2F01%2F58PIC2958PICbAX_1024.jpg";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:imagePath]];
    
    
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
//            [MBProgressHUD hideHUDForView:UIApplication.sharedApplication.keyWindow animated:YES];
        }];
        NSLog(@"currentThread : %@",[NSThread currentThread]);

        if (error)
        {
            NSLog(@"请求失败：%@",error);
        }
        else
        {
            NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            NSString *newFilePath = [documentsPath stringByAppendingPathComponent:response.suggestedFilename];
            [[NSFileManager defaultManager] moveItemAtPath:location.path toPath:newFilePath error:nil];

            NSLog(@"请求成功：%@",newFilePath);
            [NSOperationQueue.mainQueue addOperationWithBlock:^{
//                [MBProgressHUD hideHUDForView:UIApplication.sharedApplication.keyWindow animated:YES];
                filePath(newFilePath);
            }];

            //解析拿到的响应数据
        }
    }];
    [downloadTask resume];
    
}


@end
