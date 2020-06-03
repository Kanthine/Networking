//
//  RequestURL.h
//  Networking
//
//  Created by 苏沫离 on 2020/6/2.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#ifndef RequestURL_h

#define RequestURL_h


#define PostTimeOutInterval 15.0f  //post网络请求时间
#define UploadTimeOutInterval 40.0f  //文件上传网络请求时间

#ifdef DEBUG//条件编译

//#define DOMAINBASE @"https://long.马帅.cn"


#define DOMAINBASE @"https://long.xn--bttn85k.cn"
//#define DOMAINBASE @"https://180.76.140.80:443"

#else

#define DOMAINBASE @"https://long.马帅.cn"


#endif



#define URL_Test @"fancy/test"
#define URL_Login @"fancy/userService.do?method=loginApp"
#define URL_Register @"fancy/userService.do?method=regApp"
#define URL_Update_Header @"fancy/userService.do?method=updatePhoto"
#define URL_Load_Header @"fancy/userService.do?method=updatePhoto"
#define URL_File_List @"fancy/userService.do?method=getFileListOrFile"
#define URL_File_Upload @"fancy/userService.do?method=updateFile"
#define URL_File_Download @"fancy/userService.do?method=makeFolder&path="


#define URL_CityList @"fancy/tools/getCity"

#endif /* RequestURL_h */
