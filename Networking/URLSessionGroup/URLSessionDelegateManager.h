//
//  URLSessionDelegateManager.h
//  Networking
//
//  Created by 苏沫离 on 2020/6/2.
//  Copyright © 2020 苏沫离. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface URLSessionDelegateManager : NSObject
<NSURLSessionDelegate,NSURLSessionDataDelegate>

@end
/*
 @protocol NSURLSessionDelegate <NSObject>
 @protocol NSURLSessionTaskDelegate <NSURLSessionDelegate>
 @protocol NSURLSessionDataDelegate <NSURLSessionTaskDelegate> (NSURLSessionDataTask)
 @protocol NSURLSessionDownloadDelegate <NSURLSessionTaskDelegate>
 @protocol NSURLSessionStreamDelegate <NSURLSessionTaskDelegate>
 
 NSURLSessionDelegate 主要关于会话的，比如会话关闭，会话收到挑战
 NSURLSessionTaskDelegate 主要关于任务的，可以理解为任务共用的协议，比如任务完成或失败，任务收到挑战，任务将要执行HTTP重定向。
 NSURLSessionDataTask 对应 NSURLSessionDataDelegate，该协议主要用来处理dataTask的数据处理（比如接收到响应，接收到数据，是否缓存数据）
 */

//https://www.jianshu.com/p/94d214129d4d
/* NSURLSession 代理方法：
 一、身份验证或TLS握手
 这是所有task都必须经历的一个过程. 当一个服务器请求身份验证或TLS握手期间需要提供证书的话, URLSession会调用他的代理方法URLSession:​did​Receive​Challenge:​completion​Handler:​去处理。另外, 如果连接途中收到服务器返回需要身份认证的response, 也会调用该代理方法.
 二、重定位response
 这也是所有task都有可能经历的一个过程, 如果response是HTTP重定位, session会调用代理的URLSession:​task:​will​Perform​HTTPRedirection:​new​Request:​completion​Handler:方法. 这里需要调用completionHandler告诉session是否允许重定位, 或者重定位到另一个URL, 或者传nil表示重定位的响应body有效并返回. 如果代理没有实现该方法, 则允许重定位直到达到最大重定位次数.
 三、DataTask
 1、对于一个data task来说, session会调用代理的URLSession:​data​Task:​did​Receive​Response:​completion​Handler:​方法, 决定是否将一个data dask转换成download task, 然后调用completion回调继续接收data或下载data.
 如果你的app选择转换成download task, session会调用代理的URLSession:​data​Task:​did​Become​Download​Task:​方法并把新的download task对象以方法参数的形式传给你. 之后代理不会再收到data task的回调而是转为收到download task的回调
 2、在服务器传输数据给客户端期间, 代理会周期性地收到URLSession:​data​Task:​did​Receive​Data:​回调
 4、session会调用URLSession:​data​Task:​will​Cache​Response:​completion​Handler:​询问你的app是否允许缓存. 如果代理不实现这个方法的话, 默认使用session绑定的Configuration的缓存策略.
 四、DownloadTask
 1、对于一个通过download​Task​With​Resume​Data:​创建的下载任务, session会调用代理的URLSession:​download​Task:​did​Resume​At​Offset:​expected​Total​Bytes:​方法.
 2、在服务器传输数据给客户端期间, 调用URLSession:​download​Task:​did​Write​Data:​total​Bytes​Written:​total​Bytes​Expected​To​Write:给用户传数据
    当用户暂停下载时, 调用cancel​By​Producing​Resume​Data:​给用户传已下好的数据.
    如果用户想要恢复下载, 把刚刚的resumeData以参数的形式传给download​Task​With​Resume​Data:​方法创建新的task继续下载.
 3、如果download task成功完成了, 调用URLSession:​download​Task:​did​Finish​Downloading​To​URL:把临时文件的URL路径给你. 此时你应该在该代理方法返回以前读取他的数据或者把文件持久化.
 五、UploadTask
 上传数据去服务器期间, 代理会周期性收到URLSession:​task:​did​Send​Body​Data:​total​Bytes​Sent:​total​Bytes​Expected​To​Send:回调并获得上传进度的报告.
 六、StreamTask
 如果任务的数据是由一个stream发出的, session就会调用代理的URLSession:​task:​need​New​Body​Stream:​方法去获取一个NSInputStream对象并提供一个新请求的body data.
 七、task completion
 任何task完成的时候, 都会调用URLSession:​task:​did​Complete​With​Error:​方法, error有可能为nil(请求成功), 不为nil(请求失败)
 请求失败, 但是该任务是可恢复下载的, 那么error对象的userInfo字典里有一个NSURLSession​Download​Task​Resume​Data对应的value, 你应该把这个值传给download​Task​With​Resume​Data:​方法重新恢复下载
 请求失败, 但是任务无法恢复下载, 那么应该重新创建一个下载任务并从头开始下载.
 因为其他原因(如服务器错误等等), 创建并恢复请求.
 注意：NSURLSession不会收到服务器传来的错误, 代理只会收到客户端出现的错误, 例如无法解析主机名或无法连接上主机等等. 客户端错误定义在URL Loading System Error Codes. 服务端错误通过HTTP状态法进行传输,
 八、销毁 Session
 如果你不再需要一个session了, 一定要调用它的 invalidateAndCancel 或 finishTasksAndInvalidate 方法.
 否则的话, 有可能造成内存泄漏. 另外, session 失效后会调用URLSession:​did​Become​Invalid​With​Error:方法, 之后session释放对代理的强引用.
 1、invalidateAndCancel：取消所有未完成的任务然后使session失效
 2、finishTasksAndInvalidate ：等待正在执行的任务完成之后再使session失效
 九、后台 Session
 1、后台 Session 的注意点：
 （1）、后台 session 必须提供一个代理处理突发事件
 （2）、只支持HTTP(S)协议. 其他协议都不可用.
 （3）、只支持上传/下载任务, data任务不支持.
 （4）、后台任务有数量限制
 （5）、当任务数量到达系统指定的临界值的时候, 一些后台任务就会被取消. 也就是说, 一个需要长时间上传/下载的任务很可能会被系统取消然后有可能过一会再重新开始, 所以支持断点续传很重要.
 （6）、如果一个后台传输任务是在app在后台的时候开启的, 那么这个任务很可能会出于对性能的考虑随时被系统取消掉. (相当于session的Configuration对象的discretionary属性为true.)
 后台session限制确实很多, 所以尽可能使用前台session做事情.
 2、后台 Session 优化：后台session最好用来传输一些支持断点续传大文件. 或对这个过程进行一些针对性的优化
 （1）、最好把文件先压缩成zip/tar等压缩文件再上传/下载.
 （2）、把大文件按数据段分别发送, 发送完之后服务端再把数据拼接起来.
 （3）、上传的时候服务端应该返回一个标识符, 这样可以追踪传输的状态, 及时做出传输的调整
 （4）、增加一个web代理服务器中间层, 以促进上述的优化
 3、后台 Session 的使用：
    那么如何使用这个后台传输呢?
 第一步：创建一个后台session
    [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.long.backgroundSession"];
    [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
 第二步：创建一个dataTask
    [self.session downloadTaskWithRequest:request];
 注意：后台任务不能使用带有completionHandler的方法创建
     如果任务只想在app进入后台后才处理, 那么可不调用[task resume]主动执行, 待程序进入后台后会自动执行
 
 -[AppDelegate application:handleEventsForBackgroundURLSession:completionHandler:]
 -[DownloadViewController URLSession:downloadTask:didFinishDownloadingToURL:]
 -[DownloadViewController URLSession:task:didCompleteWithError:]
 -[DownloadViewController URLSessionDidFinishEventsForBackgroundURLSession:]
 4、总结后台传输：
 （1）、尽量用真机进行调试, 模拟器会跳过某一两个方法
 （2）、只能进行upload/download task, 不能进行data task
 （3）、不能使用带completionHandler的方法创建task, 否则程序直接挂掉
 （4）、Applecation里的completionHandler必须存储起来, 等你处理完所有事情之后再调用告诉系统可以进行Snapshot和挂起app了
 （5）、后台下载最好支持断点续传, 因为任务有可能会被系统主动取消(例如系统性能下降了, 资源不够用的情况下)
 

 
 */

