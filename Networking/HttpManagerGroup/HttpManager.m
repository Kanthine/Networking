//
//  HttpManager.m
//  Networking
//
//  Created by 苏沫离 on 2020/6/2.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import "HttpManager.h"
#import "AFNetAPIClient.h"
#import "AFNetTools.h"

@interface HttpManager()

@end

@implementation HttpManager

//#pragma mark - public method
//
//+ (void)requestTest{
//    NSLog(@"IP地址：%@",[AFNetTools getIPAddress:YES]);
//    [self requestForGetUrl:URL_Test success:^(id responseObject) {
//    } failure:^(NSError *error) {
//        NSLog(@"error --get--- %@",error);
//    }];
//}
//
//+ (void)requestCityListSuccess:(void (^)(NSMutableArray<CityListModel *> *cityArray))success failure:(void (^)(NSError *error))failure{
//    [self requestTest];
//    [self requestForGetUrl:URL_CityList success:^(id responseObject) {
//        
//        if ([responseObject isKindOfClass:[NSArray class]]){
//            NSArray<NSDictionary *> *array = (NSArray *)responseObject;
//            NSMutableArray *resultArray = [NSMutableArray array];
//            [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                CityListModel *model = [CityListModel modelObjectWithDictionary:obj];
//                [resultArray addObject:model];
//            }];
//            
//            //排序
//            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
//            [resultArray sortUsingDescriptors:@[sortDescriptor]];
//            
//            [NSOperationQueue.mainQueue addOperationWithBlock:^{
//                success(resultArray);
//            }];
//        }
//        
//    } failure:^(NSError *error) {
//        [NSOperationQueue.mainQueue addOperationWithBlock:^{
//            failure(error);
//        }];
//        NSLog(@"error --get--- %@",error);
//    }];
//}
//
//+ (void)requestFileList{
//    [[AFNetAPIClient sharedClient] GET:URL_File_List parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
//        
//    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        [[AFNetAPIClient sharedClient] logSessionDataTask:task ResponseObject:responseObject];
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        
//    }];
//}
//
//+ (void)requestDownData
//{
//    [[AFNetAPIClient sharedClient] GET:URL_Load_Header parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
//        
//    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        
//    }];
//}
//
//
//#pragma mark - Private Method
//
//+ (void)requestForGetUrl:(NSString *)url success:(void (^)(id))success failure:(void (^)(NSError *))failure
//{
//    [[AFNetAPIClient sharedClient].startRequestQueue addOperationWithBlock:^{
//        [[AFNetAPIClient sharedClient] requestForGetUrl:url success:success failure:failure];
//    }];
//}
//
//+ (void)requestForPostUrl:(NSString *)url Parameters:(NSDictionary *)parameters success:(void (^)(id))success failure:(void (^)(NSError *))failure
//{
//    [[AFNetAPIClient sharedClient].startRequestQueue addOperationWithBlock:^{
//        [[AFNetAPIClient sharedClient] requestForPostUrl:url Parameters:parameters success:success failure:failure];
//    }];
//}
//


@end
