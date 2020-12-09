// AFSecurityPolicy.h
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <Security/Security.h>


/** HTTPS 的证书来源：
 * 如果是正规权威CA机构签发的证书，在系统默认信任证书列表中，则会直接通过验证，一般不需要提前安装；
 * 如果是私人签发的证书，未在系统信任列表中的证书，需要提前安装。
 */

/** 数字证书的三种验证模式
 * AFSSLPinningModeNone: 验证CA机构签发的证书
 * AFSSLPinningModePublicKey : 私人签发的证书，需要保存到客户端，要求只验证证书里的公钥，不验证证书的有效期等信息。
 * AFSSLPinningModeCertificate : 私人签发的证书，需要保存到客户端；
 *                          第一步验证证书的有效性：域名/有效期等，第二步是与服务端证书的一致性。
 */
typedef NS_ENUM(NSUInteger, AFSSLPinningMode) {
    AFSSLPinningModeNone,
    AFSSLPinningModePublicKey,
    AFSSLPinningModeCertificate,
};

NS_ASSUME_NONNULL_BEGIN

/** AFSecurityPolicy 针对 HTTPS 连接时做的证书认证：验证通过“数字证书标准X.509” 的数字证书和PublicKey的网络连接是否安全
 * 在应用内添加 SSL 证书能够有效的防止中间人的攻击和安全漏洞；涉及用户敏感或隐私数据或金融信息的应用全部网络连接最好采用SSL的HTTPS连接。
 */
@interface AFSecurityPolicy : NSObject <NSSecureCoding, NSCopying>


///证书的验证方案：默认为 AFSSLPinningModeNone
@property (readonly, nonatomic, assign) AFSSLPinningMode SSLPinningMode;

/** 本地所有可用做校验的证书集合 ：根据 SSL pinning 模式验证服务器的证书；
 * @discuss AFNetworking 默认搜索工程中所有 .cer 的证书文件。
 *          如果想制定证书，可使用 +certificatesInBundle: 在目标路径下加载证书，
 *          然后调用 -policyWithPinningMode:withPinnedCertificates 创建一个 AFSecurityPolicy 对象
 * @note 如果启用了 pinning，只要该证书集合中有匹配的 pinned 证书，-evaluateServerTrust:forDomain: 将返回 true ；
 * @see policyWithPinningMode:withPinnedCertificates:
 */
@property (nonatomic, strong, nullable) NSSet <NSData *> *pinnedCertificates;

/// 是否允许无效的证书，默认是NO
@property (nonatomic, assign) BOOL allowInvalidCertificates;

/// 是否验证证书中的域名，默认是YES
@property (nonatomic, assign) BOOL validatesDomainName;

///-----------------------------------------
/// @name 从 Bundle 中获取证书
///-----------------------------------------

/** 获取指定目录下的证书
 * @discuss 如果使用 AFSecurityPolicy 验证证书，必须调用该方法获取已经包含在 App 应用 Bundle 中的证书，
 *          并且使用 -policyWithPinningMode:withPinnedCertificates 方法来创建实例对象。
 */
+ (NSSet <NSData *> *)certificatesInBundle:(NSBundle *)bundle;

///-----------------------------------------
/// @name 获取特定的 AFSecurityPolicy
///-----------------------------------------

/** 默认的验证策略：
 * 1. 不允许无效或过期的证书
 * 2. 验证域名
 * 3. 不对证书和公钥进行验证
 */
+ (instancetype)defaultPolicy;

///---------------------
/// @name 初始化
///---------------------

/**  创建指定验证模式的 AFSecurityPolicy
 * @param pinningMode 证书验证模式
 * @see -policyWithPinningMode:withPinnedCertificates:
 */
+ (instancetype)policyWithPinningMode:(AFSSLPinningMode)pinningMode;

/** 创建指定的 pinning 模式的 AFSecurityPolicy
 * @param pinningMode 证书验证模式
 * @param pinnedCertificates 本地所有可用做校验的证书集合 ：根据 SSL pinning 模式验证服务器的证书；
 * @see +certificatesInBundle:
 * @see -pinnedCertificates
*/
+ (instancetype)policyWithPinningMode:(AFSSLPinningMode)pinningMode withPinnedCertificates:(NSSet <NSData *> *)pinnedCertificates;

///------------------------------
/// @name Evaluating Server Trust
///------------------------------

/** 验证服务器的证书是否受信任
 * 当收到的响应来自服务器的 authentication challenge 时，调用该方法
 * @param serverTrust 来自服务器的证书
 * @param domain 域名，如果为 nil，serverTrust 的域将不被验证。
 */
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forDomain:(nullable NSString *)domain;

@end

NS_ASSUME_NONNULL_END
