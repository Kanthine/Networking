//
//  HttpProtocolManager.h
//  Networking
//
//  Created by 苏沫离 on 2020/6/2.
//  Copyright © 2020 苏沫离. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface HttpProtocolManager : NSURLProtocol


@end

/*
 https://github.com/Draveness/analyze/blob/master/contents/OHHTTPStubs/iOS%20%E5%BC%80%E5%8F%91%E4%B8%AD%E4%BD%BF%E7%94%A8%20NSURLProtocol%20%E6%8B%A6%E6%88%AA%20HTTP%20%E8%AF%B7%E6%B1%82.md
 
  NSURLProtocol 在 Cocoa 层拦截所有 HTTP 请求
 
 如何使用 NSURLProtocol 拦截 HTTP 请求？，有这个么几个问题需要去解决：
 1、如何决定哪些请求需要当前协议对象处理？
 2、对当前的请求对象需要进行哪些处理？
 3、NSURLProtocol 如何实例化？
 4、如何发出 HTTP 请求并且将响应传递给调用者？
 
 */
