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



/*
 一、NSURLsession

 与 NSURLConnection 相比，NSURLsession 最直接的改进就是可以配置每个 session 的缓存，协议，cookie，以及证书策略（credential policy），甚至跨程序共享这些信息。
 NSURLSession本身是不会进行请求的，而是通过创建task的形式进行网络请求（resume()方法的调用），同一个NSURLSession可以创建多个task，并且这些task之间的cache和cookie是共享的。
 NSURLSession 中另一大块就是 session task。它负责处理数据的加载以及文件和数据在客户端与服务端之间的上传和下载
 
 
默认会话的行为,类似于共享会话，但是允许使用委托获取数据。
可以通过调用NSURLSessionConfiguration类上的defaultSessionConfiguration方法来创建默认的会话配置。
 
短暂会话与默认会话类似，但它们不会将缓存、cookie或凭证写入磁盘。
可以通过调用NSURLSessionConfiguration类上的ephemeralSessionConfiguration方法来创建临时会话配置。
 
后台会话,允许在应用程序不运行时在后台执行内容的上传和下载。
 可以通过调用NSURLSessionConfiguration类上的backgroundSessionConfiguration:方法来创建后台会话配置。
 
 会话配置对象还包含一个指向URL缓存和cookie存储对象的引用，这些对象可以在请求和处理响应时使用，这取决于配置和请求类型。
 
 会话中的任务还共享一个公共委托，它允许您在发生各种事件时提供和获取信息——当身份验证失败时，当数据从服务器到达时，当数据准备好被缓存时，等等。使用URL会话可以逐步地列出会话执行任务时发生的事件，以及调用哪个委托方法。
 
 
 另一方面，如果您不需要委托提供的任何特性，那么您可以在创建会话时通过传递nil来使用这个API。
 
 会话对象保存对委托的强引用，直到应用程序退出或显式地使会话无效为止。如果你不使会话无效，你的应用程序就会泄露内存，直到它退出。
 
 在会话中，您可以创建任务，可选地将数据上载到服务器，然后以磁盘上的文件或内存中的一个或多个NSData对象的形式从服务器检索数据。NSURLSession API提供了三种类型的任务:
 数据任务使用NSData对象发送和接收数据。数据任务是用于向服务器发出简短的、通常是交互式的请求。
 上传任务与数据任务类似，但它们也发送数据(通常以文件的形式)，并在应用程序不运行时支持后台上传。
 下载任务以文件的形式获取数据，并在应用程序不运行时支持后台下载和上传。
 
 与大多数网络API一样，NSURLSession API是高度异步的。它以两种方式向应用程序返回数据，具体取决于您调用的方法:
 通过在传输成功完成或出现错误时调用完成处理程序块。
 通过调用会话委托上的方法作为接收数据和传输完成时的方法。
 
 除了向委托交付这些信息之外，NSURLSession API还提供了状态和进度属性，如果您需要根据任务的当前状态进行编程决策，您可以查询这些属性(但要注意它的状态随时都可能改变)。
 URL会话还支持取消、重新启动或恢复和暂停任务，并提供恢复暂停、取消或失败下载的能力。
 
 
 二、NSURLSession相关类为 :
 NSURLSession
 NSURLSessionConfiguration
 NSURLSessionDelegate
 NSURLSessionTask
 NSURLSessionTaskMetrics
 NSURLSessionTaskTransactionMetrics


 5、 NSURLSessionTaskMetrics 与 NSURLSessionTaskTransactionMetrics
 对发送请求/DNS查询/TLS握手/请求响应等各种环节时间上的统计. 更易于我们检测, 分析我们App的请求缓慢到底是发生在哪个环节, 并对此进行优化提升我们APP的性能.
 NSURLSessionTaskMetrics 对象与 NSURLSessionTask 对象一一对应.每个NSURLSessionTaskMetrics对象内有3个属性 :
 （1）、taskInterval : task从开始到结束总共用的时间
 （2）、redirectCount : task重定向的次数
 （3）、transactionMetrics : 一个task从发出请求到收到数据过程中派生出的每个子请求, 它是一个装着许多            NSURLSessionTaskTransactionMetrics对象的数组. 每个对象都代表下图的一个子过程
 API很简单, 就一个方法 : - (void)URLSession: task: didFinishCollectingMetrics:,
 当收集完成的时候就会调用该方法.
 
 三、NSURLSession 工作流程：
 第一步：设置配置
 NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
 第二步：代理队列
 NSOperationQueue *queue = [NSOperationQueue mainQueue];
 注意：此处的代理队列，为代理中的代码所在队列
 第三步：创建 session
 NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:queue];
 第四步：利用 session 创建 多个 task
 NSURLSessionDownloadTask *task = [session downloadTaskWithURL:[NSURL URLWithString:@""]];
 第五步：开始
 [task resume];
 注意：刚创建出来的task默认是挂起状态的，需要调用该方法来启动任务（执行任务）

 四、NSURLSession 代理方法：
 1、身份验证或TLS握手
    这是所有task都必须经历的一个过程. 当一个服务器请求身份验证或TLS握手期间需要提供证书的话, URLSession会调用他的代理方法URLSession:​did​Receive​Challenge:​completion​Handler:​去处理。另外, 如果连接途中收到服务器返回需要身份认证的response, 也会调用该代理方法.
 2、重定位response
    这也是所有task都有可能经历的一个过程, 如果response是HTTP重定位, session会调用代理的URLSession:​task:​will​Perform​HTTPRedirection:​new​Request:​completion​Handler:方法. 这里需要调用completionHandler告诉session是否允许重定位, 或者重定位到另一个URL, 或者传nil表示重定位的响应body有效并返回. 如果代理没有实现该方法, 则允许重定位直到达到最大重定位次数.
 3、DataTask
    对于一个data task来说, session会调用代理的URLSession:​data​Task:​did​Receive​Response:​completion​Handler:​方法, 决定是否将一个data dask转换成download task, 然后调用completion回调继续接收data或下载data.
    如果你的app选择转换成download task, session会调用代理的URLSession:​data​Task:​did​Become​Download​Task:​方法并把新的download task对象以方法参数的形式传给你. 之后代理不会再收到data task的回调而是转为收到download task的回调
    在服务器传输数据给客户端期间, 代理会周期性地收到URLSession:​data​Task:​did​Receive​Data:​回调
    session会调用URLSession:​data​Task:​will​Cache​Response:​completion​Handler:​询问你的app是否允许缓存. 如果代理不实现这个方法的话, 默认使用session绑定的Configuration的缓存策略.
 4、DownloadTask
    对于一个通过download​Task​With​Resume​Data:​创建的下载任务, session会调用代理的URLSession:​download​Task:​did​Resume​At​Offset:​expected​Total​Bytes:​方法.
    在服务器传输数据给客户端期间, 调用URLSession:​download​Task:​did​Write​Data:​total​Bytes​Written:​total​Bytes​Expected​To​Write:给用户传数据
 
 五、NSURLSession API
 1、创建Session：
 + session​With​Configuration:​​ : 创建一个指定配置的session
 + session​With​Configuration:​​delegate:​​delegate​Queue:​​ : 创建一个指定配置, 代理和代理方法执行队列的session
 shared​Session : 返回session单例
 2、配置Session
 configuration : 配置
 delegate : 代理对象
 delegateQueue : 代理方法的执行队列
 sessionDescription : app定义的对于该session的描述
 3、添加data任务：
 - dataTaskWithURL: : 获取指定URL内容
 - dataTaskWithURL:completionHandler: : 获取指定URL内容, 在completionHandler中处理数据. 该方法会绕过代理方法(除了身份认证挑战的代理方法)
 - data​Task​With​Request:​​ : 获取指定URLRequest内容
 - data​Task​With​Request:​​completionHandler: : 获取指定URLRequest内容, 在completionHandler中处理数据. 该方法会绕过代理方法(除了身份认证挑战的代理方法)
 4、添加download任务
 - downloadTaskWithURL: : 下载指定URL内容
 - downloadTaskWithURL:completionHandler: : 下载指定URL内容, 在completionHandler中处理数据. 该方法会绕过代理方法(除了身份认证挑战的代理方法)
 - downloadTask​With​Request:​​ : 下载指定URLRequest内容
 - downloadTask​With​Request:​​completionHandler: : 下载指定URLRequest内容, 在completionHandler中处理数据. 该方法会绕过代理方法(除了身份认证挑战的代理方法)
 - downloadTask​With​ResumeData:​​ : 创建一个之前被取消/下载失败的download task
 - downloadTask​With​ResumeData:​​completionHandler: : 创建一个之前被取消/下载失败的download task, 在completionHandler中处理数据. 该方法会绕过代理方法(除了身份认证挑战的代理方法)
 5、添加upload任务
 - upload​Task​With​Request:​​from​Data:​​ : 通过HTTP请求发送data给指定URL
 - upload​Task​With​Request:​​from​Data:completionHandler: : 通过HTTP请求发送data给指定URL, 在completionHandler中处理数据. 该方法会绕过代理方法(除了身份认证挑战的代理方法)
 - upload​Task​With​Request:​​from​File:​​ : 通过HTTP请求发送指定文件给指定URL
 - upload​Task​With​Request:​​from​File:completionHandler: : 通过HTTP请求发送指定文件给指定URL, 在completionHandler中处理数据. 该方法会绕过代理方法(除了身份认证挑战的代理方法)
 upload​Task​With​StreamedRequest : 通过HTTP请求发送指定URLRequest数据流给指定URL
 6、添加 stream 任务
 - streamTask​With​HostName:port:​​ : 通过给定的域名和端口建立双向TCP/IP连接
 - streamTask​With​NetService: : 通过给定的network service建立双向TCP/IP连接
 7、管理session
 finishTasksAndInvalidate : 任务全部完成后销毁session
 flushWithCompletionHandler: : 清除硬盘上的cookies和证书, 清理暂时的缓存, 确保未来能响应一个新的TCP请求
 getTasksWithCompletionHandler: : 异步调用session中所有upload, download, data tasks的completion回调.
 invalidateAndCancel : 取消所有未完成的任务并销毁session
 resetWithCompletionHandler: : 清空cookies, 缓存和证书存储, 移除所有磁盘文件, 清理正在执行的下载任务, 确保未来能响应一个新的socket请求
 8、API总结
 所有创建task的方法, 只要带有completionHandler这个参数的, 均表示为请求过程中不会触发代理方法. 所有不带有completionHandler这个参数的, 均会走代理方法流程.
 如果你实现了URLSession:​did​Receive​Challenge:​completion​Handler:​方法又没有在该方法调用completionHandler, 请求就会遭到阻塞
 
 六、断点续传
 下载失败/暂停/被取消, 可以通过task的- cancel​By​Producing​Resume​Data:​方法保存已下载的数据, 然后调用session的download​Task​With​Resume​Data:​方法, 触发代理的URLSession:​download​Task:​did​Resume​At​Offset:​expected​Total​Bytes:​方法
 
 七、NSCopying Behavior
 session, task和 configuration 对象都支持 copy 操作 :
 session/task copy : 返回session对象本身
 configuration copy : 返回一个无法修改(immutable)的对象.
 八、线程安全：
 URLSession 的API全部都是线程安全的. 你可以在任何线程上创建session和tasks, task会自动调度到合适的代理队列中运行.
 注意：后台传输的代理方法URLSession​Did​Finish​Events​For​Background​URLSession:​可能会在其他线程中被调用. 在该方法中你应该回到主线程然后调用completion handler去触发AppDelegate中的application:​handle​Events​For​Background​URLSession:​completion​Handler:​方法.
 
*/

