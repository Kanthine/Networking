//
//  HttpManager+UploadFile.m
//  objective_c_language
//
//  Created by 王玉龙 on 2018/6/4.
//  Copyright © 2018年 longlong. All rights reserved.
//

#import "HttpManager+UploadFile.h"
#import "AFNetAPIClient.h"

@implementation HttpManager (UploadFile)

//+ (void)upLoadImage:(UIImage *)image
//{
//    if (!image)
//    {
//        image = [UIImage imageNamed:@"my_Back"];
//    }
//    
//    [[AFNetAPIClient sharedClient] POST:URL_Update_Header parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
//        
//        NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
//        
//        // data 数据  name 参数名称  fileName 文件名称  mimeType 文件类型
//        [formData appendPartWithFileData:imageData name:@"header" fileName:@"header.png" mimeType:@"image/jpeg"];
//        
//    } progress:^(NSProgress * _Nonnull uploadProgress) {
//        
//        
//        NSLog(@"uploadProgress ---- %@",uploadProgress);
//    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        
//        [[AFNetAPIClient sharedClient] logSessionDataTask:task ResponseObject:responseObject];
//        
//
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        
//        
//        NSLog(@"error ---- %@",error);
//        [UIApplication.sharedApplication.keyWindow makeToast:error.localizedFailureReason duration:5 position:CSToastPositionCenter];
//
//    }];
//    
//    
//}
//
//+ (void)upLoadImagePath:(NSString *)imagePath
//{
//    
//    [[AFNetAPIClient sharedClient] POST:URL_Update_Header parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
//        
//        // FileURL 文件地址  name 参数名称  fileName 文件名称  mimeType 文件类型
//        NSError *error;
//        [formData appendPartWithFileURL:[NSURL URLWithString:imagePath] name:@"" fileName:@"" mimeType:@"" error:&error];
//        
//        [formData appendPartWithFileURL:[NSURL URLWithString:imagePath] name:@"" error:&error];
//        
//    } progress:^(NSProgress * _Nonnull uploadProgress) {
//        
//        
//        NSLog(@"uploadProgress ---- %@",uploadProgress);
//    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        
//        [[AFNetAPIClient sharedClient] logSessionDataTask:task ResponseObject:responseObject];
//
//        
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        
//        [UIApplication.sharedApplication.keyWindow makeToast:error.localizedFailureReason duration:5 position:CSToastPositionCenter];
//
//    }];
//    
//    
//}
//
//
//+ (void)requestBigFileUploadTestProgress:(nullable void (^)(NSProgress * _Nonnull))progress
//{
//    [[AFNetAPIClient sharedClient] POST:URL_File_Upload parameters:@{} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
//        
//        
//        NSData *imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"my_Back"], 0.5);
//        [formData appendPartWithFileData:imageData name:@"header" fileName:@"header.png" mimeType:@"image/jpeg"];
//
//
//    } progress:^(NSProgress * _Nonnull uploadProgress) {
//        progress(uploadProgress);
//    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        [[AFNetAPIClient sharedClient] logSessionDataTask:task ResponseObject:responseObject];
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        NSLog(@"error ---- %@",error);
//        
//        [UIApplication.sharedApplication.keyWindow makeToast:error.localizedFailureReason duration:5 position:CSToastPositionCenter];
//        
//    }];
//}
//


@end
