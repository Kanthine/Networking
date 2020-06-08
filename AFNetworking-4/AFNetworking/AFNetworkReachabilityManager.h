#import <Foundation/Foundation.h>

#if !TARGET_OS_WATCH
#import <SystemConfiguration/SystemConfiguration.h>
//网络监控的实现是依赖SystemConfiguration这个api的

typedef NS_ENUM(NSInteger, AFNetworkReachabilityStatus) {
    AFNetworkReachabilityStatusUnknown          = -1,//未知网络
    AFNetworkReachabilityStatusNotReachable     = 0,//无网络
    AFNetworkReachabilityStatusReachableViaWWAN = 1,//手机自带网络
    AFNetworkReachabilityStatusReachableViaWiFi = 2,//WiFi网络
};

/**
如果需要每个属性或每个方法都去指定nonnull和nullable，是一件非常繁琐的事，苹果为了减轻我们的工作量，专门提供了两个宏：
NS_ASSUME_NONNULL_BEGIN 与 NS_ASSUME_NONNULL_END
在这两个宏之间的代码，所有简单指针对象都被假定为nonnull，因此我们只需要去指定那些nullable的指针
__nullable 指代对象可以为NULL或者为NIL
__nonnull 指代对象不能为null
*/

NS_ASSUME_NONNULL_BEGIN

/** AFNetworkReachabilityManager 用于监测网络环境变化：WWAN 和 WiFi 以及网指定服务器
 * @warning 调用 -startMonitoring 方法确定网络状态
 *
 * 参考苹果官方 Reachability 的源码(https://developer.apple.com/library/ios/samplecode/reachability/ )
 */
@interface AFNetworkReachabilityManager : NSObject

/** 当前的网络状态 */
@property (readonly, nonatomic, assign) AFNetworkReachabilityStatus networkReachabilityStatus;

/** 是否联网 */
@property (readonly, nonatomic, assign, getter = isReachable) BOOL reachable;

/** 当前是否是流量网 */
@property (readonly, nonatomic, assign, getter = isReachableViaWWAN) BOOL reachableViaWWAN;

/** 当前是否是WiFi */
@property (readonly, nonatomic, assign, getter = isReachableViaWiFi) BOOL reachableViaWiFi;

///---------------------
/// @name Initialization
///---------------------

/** 获取监测器单例
 */
+ (instancetype)sharedManager;

/** 获取监测器 */
+ (instancetype)manager;

/** 创建指定服务器域名的监测器
 * @param domain 待评估网络状态的服务器域名
 */
+ (instancetype)managerForDomain:(NSString *)domain;

/** 监听某个socket的网络状态
 */
+ (instancetype)managerForAddress:(const void *)address;

/** 主动监控指定的SCNetworkReachabilityRef
 * @param reachability 要监视的 SCNetworkReachabilityRef
 * @note SCNetworkReachabilityRef 这个很重要，这个类的就是基于它开发的。
 */
- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability NS_DESIGNATED_INITIALIZER;

/**  禁用该初始化方法
 */
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

///--------------------------------------------------
/// @name 启动和停止监听
///--------------------------------------------------


/** 开始监听 */
- (void)startMonitoring;

/** 停止监听 */
- (void)stopMonitoring;

///-------------------------------------------------
/// @name 获取本地化的 Reachability 描述
///-------------------------------------------------

/** 获取当前网络状态的本地化字符串表示
 * 往往我们可以根据这个字符串来告诉用户，当前网络发生了什么，当然，也可以根据状态自定义提示文字。
 */
- (NSString *)localizedNetworkReachabilityStatusString;

///---------------------------------------------------
/// @name 网络状态变化的回调
///---------------------------------------------------

/** 当主机 baseURL 网络状态变化时执行的回调
 * @note 也可以使用通知 AFNetworkingReachabilityDidChangeNotification 监听网络变化
 */
- (void)setReachabilityStatusChangeBlock:(nullable void (^)(AFNetworkReachabilityStatus status))block;

@end

///----------------
/// @name 常量
///----------------

/** AFNetworkReachabilityManager 提供的主机 baseURL 网络状态
 *  <ul>
 *     <li> AFNetworkReachabilityStatusUnknown  网络状态未知
 *     <li> AFNetworkReachabilityStatusNotReachable  网络不可链接
 *     <li> AFNetworkReachabilityStatusReachableViaWWAN  是蜂窝网络，如EDGE或GPRS
 *     <li> AFNetworkReachabilityStatusReachableViaWiFi 是 Wi-Fi 网络
 *  </ul>
 *
 *
 * 通知中字典 UserInfo 中的键：
 *  <ul>
 *     <li> AFNetworkingReachabilityNotificationStatusItem 对应 NSNumber 对象，表示当前网络状态
 *  </ul>
 */

///--------------------
/// @name 通知
///--------------------

/** 当网络状态改变时发送的通知
 *  @warning 为了监测网络状态，将 <SystemConfiguration> 框架添加到 target's 的Link Binary With Library 。 ，并 #import <SystemConfiguration/SystemConfiguration.h> 到项目的头前缀 Prefix.pch
 */
FOUNDATION_EXPORT NSString * const AFNetworkingReachabilityDidChangeNotification;
FOUNDATION_EXPORT NSString * const AFNetworkingReachabilityNotificationStatusItem;

///--------------------
/// @name 功能
///--------------------

/** 获取 AFNetworkReachabilityStatus 值的本地化字符串表示
 */
FOUNDATION_EXPORT NSString * AFStringFromNetworkReachabilityStatus(AFNetworkReachabilityStatus status);

NS_ASSUME_NONNULL_END
#endif
