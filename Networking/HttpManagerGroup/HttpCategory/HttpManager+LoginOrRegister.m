//
//  HttpManager+LoginOrRegister.m
//  objective_c_language
//
//  Created by 王玉龙 on 2018/6/4.
//  Copyright © 2018年 longlong. All rights reserved.
//

#import "HttpManager+LoginOrRegister.h"
#import "AFNetAPIClient.h"

@implementation HttpManager (LoginOrRegister)

//+ (void)requestLoginWithAccount:(NSString *)account Password:(NSString *)password Success:(void (^)(AccountManager *account))success failure:(void (^)(NSError *error))failure
//{
//    if (account == nil || password == nil)
//    {
//        return;
//    }
//    NSDictionary *dict = @{@"userName":account,@"userPwd":password};
//    
//    [self requestForPostUrl:URL_Login Parameters:dict success:^(id responseObject) {
//        
//        if ([responseObject[@"code"] intValue] == 0)
//        {
//            [DataLocalManager storeAccount:account Password:password];
//            AccountManager *account = [AccountManager modelObjectWithDictionary:responseObject[@"result"][@"data"]];
//            [account storeAccountInfo];
//            [NSOperationQueue.mainQueue addOperationWithBlock:^{
//                success(account);
//            }];
//        }
//        else
//        {
//            NSString *string = [NSString stringWithFormat:@"%@",responseObject[@"message"]];
//            NSError *error = [NSError errorWithDomain:string code:[responseObject[@"code"] intValue] userInfo:nil];
//            
//            [NSOperationQueue.mainQueue addOperationWithBlock:^{
//                failure(error);
//            }];
//        }
//        
//    } failure:^(NSError *error) {
//        [NSOperationQueue.mainQueue addOperationWithBlock:^{
//            failure(error);
//        }];
//    }];
//}
//
//
//+ (void)requestRegisterWithAccount:(NSString *)account Password:(NSString *)password Email:(NSString *)email Success:(void (^)(AccountManager *account))success failure:(void (^)(NSError *error))failure
//{
//    if (account == nil || password == nil || email == nil)
//    {
//        return;
//    }
//    NSDictionary *dict = @{@"userName":account,
//                           @"nickName":@"",
//                           @"userPwd":password,
//                           @"userPwd2":password,
//                           @"email":email};
//    
//    
//    [self requestForPostUrl:URL_Register Parameters:dict success:^(id responseObject) {
//        
//        if ([responseObject[@"code"] intValue] == 0)
//        {
//            [DataLocalManager storeAccount:account Password:password];
//            AccountManager *account = [AccountManager modelObjectWithDictionary:responseObject[@"result"][@"data"]];
//            [account storeAccountInfo];
//            [NSOperationQueue.mainQueue addOperationWithBlock:^{
//                success(account);
//            }];
//            
//        }
//        else
//        {
//            NSError *error = [NSError errorWithDomain:responseObject[@"message"] code:[responseObject[@"code"] intValue] userInfo:nil];
//            [NSOperationQueue.mainQueue addOperationWithBlock:^{
//                failure(error);
//            }];
//        }
//        
//    } failure:^(NSError *error) {
//        [NSOperationQueue.mainQueue addOperationWithBlock:^{
//            failure(error);
//        }];
//        
//        NSLog(@"error --get--- %@",error);
//    }];
//}


@end
