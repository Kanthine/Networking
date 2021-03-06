// AFSecurityPolicy.m
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

#import "AFSecurityPolicy.h"

#import <AssertMacros.h>

#if !TARGET_OS_IOS && !TARGET_OS_WATCH && !TARGET_OS_TV

/** 函数 SecItemExport()
 * 该函数接受一个或多个 SecItemRefs，并以 CFDataRef 的形式创建 item(s) 的外部表示。
 * 调用者通过 SecExternalFormat enum 指定外部表示的格式。
 * 调用者指定格式为 kSecFormatUnknown，将使用导出项的默认格式(如SecExternalFormat enums中所述)。
 * PEM armouring 是可选的，由 importFlags 中的 kSecItemPemArmour flag指定。
 *
 * 如果要精确地导出一个 item ，则 keychainItemOrArray 参数可以是 SecKeychainItem；否则，此参数为 CFArrayRef，包含许多 SecKeychainItems ！
 *
 * 导出的 item(s) 通过 CFDataRef *exportedData 参数返回给调用者；调用者需要注意释放这些结果！
 *
 * 以下的 SecKeychainItems 可被导出:
 *  <ul>
 *     <li> SecCertificateRef
 *     <li> SecKeyRef
 *     <li> SecIdentityRef
 *  </ul>
 *
 * 密钥相关 SecItemExport 字段
 * -----------------------------------------------
 *
 * 当以一种 wrapped 格式(kSecFormatWrappedOpenSSL、kSecFormatWrappedSSH、kSecFormatWrappedPKCS8)或 PKCS12 格式导出 SecKeyRefs 时，调用者必须显式指定 passphrase 字段或在 SecKeyImportExportFlags 中设置 kSecKeySecurePassphrase 位。
 *
 * 如果选择了 kSecKeySecurePassphrase ，调用者可以有选择地为 passphrase panel 的标题栏和通过 SecItemImportExportKeyParameters 中的 alertTitle 和 alertPrompt 字段在 panel via 显示的提示指定字符串。
 *
 * 如果指定了显式口令，请注意 PKCS12 显式要求口令为 Unicode 格式;传入 CFStringRef 作为密码短语是确保满足此要求(并且结果将与其他实现兼容)的最安全的方法。
 * 如果CFDataRef作为PKCS12导出操作的口令提供，则假定引用数据为UTF8形式，并将根据需要进行转换。 *
 * 如果没有导出 key items ，则keyParams参数可以为NULL。
 *
 
OSStatus SecItemExport(CFTypeRef secItemOrArray,SecExternalFormat outputFormat,SecItemImportExportFlags flags,
 const SecItemImportExportKeyParameters * __nullable keyParams, CFDataRef * __nonnull CF_RETURNS_RETAINED exportedData);
 *
*/

//主要是把key到出为NSData
static NSData * AFSecKeyGetData(SecKeyRef key) {
    CFDataRef data = NULL;
    __Require_noErr_Quiet(SecItemExport(key, kSecFormatUnknown, kSecItemPemArmour, NULL, &data), _out);
    return (__bridge_transfer NSData *)data;
_out:
    if (data) {
        CFRelease(data);
    }
    return nil;
}

#endif
//这个方法是比较两个key是否相等，如果是ios/watch/tv直接使用isEqual方法就可进行比较。应为SecKeyRef本质上是一个struct，是不能直接用isEqual比较的，正好使用上边的那个方法把它转为NSData就可以了。
static BOOL AFSecKeyIsEqualToKey(SecKeyRef key1, SecKeyRef key2) {
#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
    return [(__bridge id)key1 isEqual:(__bridge id)key2];
#else
    return [AFSecKeyGetData(key1) isEqual:AFSecKeyGetData(key2)];
#endif
}

/// 在证书中获取公钥
static id AFPublicKeyForCertificate(NSData *certificate) {
    id allowedPublicKey = nil;
    SecCertificateRef allowedCertificate;
    SecPolicyRef policy = nil;
    SecTrustRef allowedTrust = nil;
    SecTrustResultType result;
    // 1. 根据二进制的certificate生成SecCertificateRef类型的证书
    allowedCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificate);
    __Require_Quiet(allowedCertificate != NULL, _out);//当条件返回false时，执行标记以后的代码
    // 2.如果allowedCertificate为空，则执行标记_out后边的代码
    // 5. 新建policy为X.509
    policy = SecPolicyCreateBasicX509();
    // 6.创建SecTrustRef对象，如果出错就跳到_out标记处
    __Require_noErr_Quiet(SecTrustCreateWithCertificates(allowedCertificate, policy, &allowedTrust), _out);//当条件抛出异常时，执行标记以后的代码
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    
    // 7.校验证书的过程，这个不是异步的
    __Require_noErr_Quiet(SecTrustEvaluate(allowedTrust, &result), _out);
#pragma clang diagnostic pop
    
    // 8.在SecTrustRef对象中取出公钥

    allowedPublicKey = (__bridge_transfer id)SecTrustCopyPublicKey(allowedTrust);

_out:
    if (allowedTrust) {
        CFRelease(allowedTrust);
    }

    if (policy) {
        CFRelease(policy);
    }

    if (allowedCertificate) {
        CFRelease(allowedCertificate);
    }

    return allowedPublicKey;
}

//服务器是否可信任的
static BOOL AFServerTrustIsValid(SecTrustRef serverTrust) {
    BOOL isValid = NO;
    SecTrustResultType result;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    __Require_noErr_Quiet(SecTrustEvaluate(serverTrust, &result), _out);
#pragma clang diagnostic pop

    isValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);

_out:
    return isValid;
}

//取出服务器返回的所有证书
static NSArray * AFCertificateTrustChainForServerTrust(SecTrustRef serverTrust) {
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];
    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        [trustChain addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
    }
    return [NSArray arrayWithArray:trustChain];
}

//取出服务器返回的所有证书的公匙
static NSArray * AFPublicKeyTrustChainForServerTrust(SecTrustRef serverTrust) {
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];
    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);

        SecCertificateRef someCertificates[] = {certificate};
        CFArrayRef certificates = CFArrayCreate(NULL, (const void **)someCertificates, 1, NULL);

        SecTrustRef trust;
        __Require_noErr_Quiet(SecTrustCreateWithCertificates(certificates, policy, &trust), _out);
        SecTrustResultType result;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        __Require_noErr_Quiet(SecTrustEvaluate(trust, &result), _out);
#pragma clang diagnostic pop
        [trustChain addObject:(__bridge_transfer id)SecTrustCopyPublicKey(trust)];

    _out:
        if (trust) {
            CFRelease(trust);
        }

        if (certificates) {
            CFRelease(certificates);
        }

        continue;
    }
    CFRelease(policy);

    return [NSArray arrayWithArray:trustChain];
}

#pragma mark -

@interface AFSecurityPolicy()
@property (readwrite, nonatomic, assign) AFSSLPinningMode SSLPinningMode;
@property (readwrite, nonatomic, strong) NSSet *pinnedPublicKeys;
@end

@implementation AFSecurityPolicy
//获取某个包下的所有证书
+ (NSSet *)certificatesInBundle:(NSBundle *)bundle {
    NSArray *paths = [bundle pathsForResourcesOfType:@"cer" inDirectory:@"."];

    NSMutableSet *certificates = [NSMutableSet setWithCapacity:[paths count]];
    for (NSString *path in paths) {
        NSData *certificateData = [NSData dataWithContentsOfFile:path];
        [certificates addObject:certificateData];
    }

    return [NSSet setWithSet:certificates];
}

+ (instancetype)defaultPolicy {
    AFSecurityPolicy *securityPolicy = [[self alloc] init];
    securityPolicy.SSLPinningMode = AFSSLPinningModeNone;

    return securityPolicy;
}

+ (instancetype)policyWithPinningMode:(AFSSLPinningMode)pinningMode {
    NSSet <NSData *> *defaultPinnedCertificates = [self certificatesInBundle:[NSBundle mainBundle]];
    return [self policyWithPinningMode:pinningMode withPinnedCertificates:defaultPinnedCertificates];
}

+ (instancetype)policyWithPinningMode:(AFSSLPinningMode)pinningMode withPinnedCertificates:(NSSet *)pinnedCertificates {
    AFSecurityPolicy *securityPolicy = [[self alloc] init];
    securityPolicy.SSLPinningMode = pinningMode;

    [securityPolicy setPinnedCertificates:pinnedCertificates];

    return securityPolicy;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.validatesDomainName = YES;

    return self;
}

- (void)setPinnedCertificates:(NSSet *)pinnedCertificates {
    _pinnedCertificates = pinnedCertificates;

    if (self.pinnedCertificates) {
        NSMutableSet *mutablePinnedPublicKeys = [NSMutableSet setWithCapacity:[self.pinnedCertificates count]];
        for (NSData *certificate in self.pinnedCertificates) {
            id publicKey = AFPublicKeyForCertificate(certificate);
            if (!publicKey) {
                continue;
            }
            [mutablePinnedPublicKeys addObject:publicKey];
        }
        self.pinnedPublicKeys = [NSSet setWithSet:mutablePinnedPublicKeys];
    } else {
        self.pinnedPublicKeys = nil;
    }
}

#pragma mark -

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forDomain:(NSString *)domain{
    if (domain &&
        self.allowInvalidCertificates &&
        self.validatesDomainName &&
        (self.SSLPinningMode == AFSSLPinningModeNone || [self.pinnedCertificates count] == 0)) {
        //如果要验证自签名证书的域名，那么就不能用 AFSSLPinningModeNone 模式，而且服务器制作的证书必须在客户端保存一份
        //  From Apple Docs:
        //          "Do not implicitly trust self-signed certificates as anchors (kSecTrustOptionImplicitAnchors).
        //           Instead, add your own (self-signed) CA certificate to the list of trusted anchors."
        
        //如果要验证自签名证书的域名，那么就不能用 AFSSLPinningModeNone 模式，而且服务器制作的证书必须在客户端保存一份
        NSLog(@"In order to validate a domain name for self signed certificates, you MUST use pinning.");
        return NO;
    }

    NSMutableArray *policies = [NSMutableArray array];
    // 需要验证域名时，需要添加一个验证域名的策略
    if (self.validatesDomainName) {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
    } else {
        [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
    }

    //设置验证的策略
    SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);

    if (self.SSLPinningMode == AFSSLPinningModeNone) {
        return self.allowInvalidCertificates || AFServerTrustIsValid(serverTrust);
    } else if (!self.allowInvalidCertificates && !AFServerTrustIsValid(serverTrust)) {
        return NO;
    }

    switch (self.SSLPinningMode) {
        case AFSSLPinningModeCertificate: {
            NSMutableArray *pinnedCertificates = [NSMutableArray array];
            for (NSData *certificateData in self.pinnedCertificates) {
                [pinnedCertificates addObject:(__bridge_transfer id)SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData)];
            }
            SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)pinnedCertificates);

            if (!AFServerTrustIsValid(serverTrust)) {
                return NO;
            }

            // obtain the chain after being validated, which *should* contain the pinned certificate in the last position (if it's the Root CA)
            NSArray *serverCertificates = AFCertificateTrustChainForServerTrust(serverTrust);
            
            for (NSData *trustChainCertificate in [serverCertificates reverseObjectEnumerator]) {
                if ([self.pinnedCertificates containsObject:trustChainCertificate]) {
                    return YES;
                }
            }
            
            return NO;
        }
        case AFSSLPinningModePublicKey: {
            NSUInteger trustedPublicKeyCount = 0;
            NSArray *publicKeys = AFPublicKeyTrustChainForServerTrust(serverTrust);

            for (id trustChainPublicKey in publicKeys) {
                for (id pinnedPublicKey in self.pinnedPublicKeys) {
                    if (AFSecKeyIsEqualToKey((__bridge SecKeyRef)trustChainPublicKey, (__bridge SecKeyRef)pinnedPublicKey)) {
                        trustedPublicKeyCount += 1;
                    }
                }
            }
            return trustedPublicKeyCount > 0;
        }
            
        default:
            return NO;
    }
    
    return NO;
}

#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingPinnedPublicKeys {
    return [NSSet setWithObject:@"pinnedCertificates"];
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {

    self = [self init];
    if (!self) {
        return nil;
    }

    self.SSLPinningMode = [[decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(SSLPinningMode))] unsignedIntegerValue];
    self.allowInvalidCertificates = [decoder decodeBoolForKey:NSStringFromSelector(@selector(allowInvalidCertificates))];
    self.validatesDomainName = [decoder decodeBoolForKey:NSStringFromSelector(@selector(validatesDomainName))];
    self.pinnedCertificates = [decoder decodeObjectOfClass:[NSSet class] forKey:NSStringFromSelector(@selector(pinnedCertificates))];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:self.SSLPinningMode] forKey:NSStringFromSelector(@selector(SSLPinningMode))];
    [coder encodeBool:self.allowInvalidCertificates forKey:NSStringFromSelector(@selector(allowInvalidCertificates))];
    [coder encodeBool:self.validatesDomainName forKey:NSStringFromSelector(@selector(validatesDomainName))];
    [coder encodeObject:self.pinnedCertificates forKey:NSStringFromSelector(@selector(pinnedCertificates))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    AFSecurityPolicy *securityPolicy = [[[self class] allocWithZone:zone] init];
    securityPolicy.SSLPinningMode = self.SSLPinningMode;
    securityPolicy.allowInvalidCertificates = self.allowInvalidCertificates;
    securityPolicy.validatesDomainName = self.validatesDomainName;
    securityPolicy.pinnedCertificates = [self.pinnedCertificates copyWithZone:zone];
    return securityPolicy;
}

@end
