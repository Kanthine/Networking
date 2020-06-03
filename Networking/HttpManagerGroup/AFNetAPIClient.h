//
//  AFNetAPIClient.h
//  Networking
//
//  Created by 苏沫离 on 2020/6/2.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "RequestURL.h"

@interface AFNetAPIClient : AFHTTPSessionManager

@property (nonatomic ,strong) NSOperationQueue * _Nullable startRequestQueue;

/** 创建一个单例类
 */
+(AFNetAPIClient *)sharedClient;


-(NSURLSessionDataTask *)requestForGetUrl:(NSString*)url success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure;

-(NSURLSessionDataTask *)requestForPostUrl:(NSString*)url Parameters:(NSDictionary *)parameters success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure;

- (void)logSessionDataTask:(NSURLSessionDataTask *)task ResponseObject:(id  _Nullable) responseObject;


@end

/*
 << 二进制左移运算符。左操作数的值向左移动右操作数指定的位数。
 int a = 60;
 a = 0011 1100;(二进制)
 a << 2 值为 240;
 即为 1111 0000
 
 0000 0000 0000 0001
 
 1UL 表示 无符号长整型 1
 1UL << 1 结果是一个unsigned long int 数，让它 左移位 1
 typedef NS_OPTIONS(NSUInteger, NSJSONReadingOptions)
 {
     //返回可变容器，NSMutableDictionary或NSMutableArray
     NSJSONReadingMutableContainers = (1UL << 0),（值为 1）
 
        //不仅返回的最外层是可变的, 内部的子数值或字典也是可变对象
     //返回的JSON对象中字符串的值为NSMutableString
     NSJSONReadingMutableLeaves = (1UL << 1), 值为 2
 
     //允许JSON字符串最外层既不是NSArray也不是NSDictionary，但必须是有效的JSON Fragment。例如使用这个选项可以解析 @“123” 这样的字符串。
     NSJSONReadingAllowFragments = (1UL << 2) 值为 4
 } NS_ENUM_AVAILABLE(10_7, 5_0);
 
 
 typedef NS_OPTIONS(NSUInteger, NSJSONWritingOptions)
 {
    //是将生成的json数据格式化输出，这样可读性高，不设置则输出的json字符串就是一整行。
    NSJSONWritingPrettyPrinted = (1UL << 0),
 
    //输出的json字符串就是一整行
    NSJSONWritingSortedKeys = (1UL << 1)
}
 */
