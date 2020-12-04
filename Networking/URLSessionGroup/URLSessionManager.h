//
//  URLSessionManager.h
//  Networking
//
//  Created by 苏沫离 on 2020/6/2.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import <Foundation/Foundation.h>
#define iTunes_URL @"http://itunes.apple.com/lookup?id=1164001330"



@interface URLSessionManager : NSObject
<NSURLSessionDelegate,NSURLSessionTaskDelegate,NSURLSessionDataDelegate>

@property (nonatomic ,strong) NSOperationQueue *sessionQueue;
@property (class, readonly, strong) URLSessionManager *shareManager;

@end

#import "URLSessionManager+Block.h"
#import "URLSessionManager+Delegate.h"


