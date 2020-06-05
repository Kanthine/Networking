// AFURLResponseSerialization.h
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
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/** 递归地从一个JSON对象中移除 NSNull
 */
FOUNDATION_EXPORT id AFJSONObjectByRemovingKeysWithNullValues(id JSONObject, NSJSONReadingOptions readingOptions);

/** AFURLResponseSerialization 协议:对服务器的响应数据进行验证，并将有效的JSON数据解析为一个对象！
 * 例如，检查可接受的状态代码 [200,299] 和 contentType (application/JSON)
 */
@protocol AFURLResponseSerialization <NSObject, NSSecureCoding, NSCopying>

/** 将待解析的响应数据解码为一个对象
 *
 * @param response 待处理的响应
 * @param data 待解析的响应数据。
 * @param error 解码响应数据时遇到的错误
 * @return 解析得到的对象
 */
- (nullable id)responseObjectForResponse:(nullable NSURLResponse *)response
                           data:(nullable NSData *)data
                          error:(NSError * _Nullable __autoreleasing *)error NS_SWIFT_NOTHROW;

@end

#pragma mark -

/** AFHTTPResponseSerializer 处理所有的HTTP请求的响应，提供响应报文可接受HTTP的状态码，验证响应状态码和有效的 Content-Type 。
 */
@interface AFHTTPResponseSerializer : NSObject <AFURLResponseSerialization>

- (instancetype)init;

/** 创建具有默认配置的序列化器
 */
+ (instancetype)serializer;

///-----------------------------------------
/// @name 配置响应序列化器
///-----------------------------------------

/** 响应报文可接受HTTP的状态码。当不是 nil 时，如果响应的状态码不在该集合中，则会在验证过程中出现错误。
 * See http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
 */
@property (nonatomic, copy, nullable) NSIndexSet *acceptableStatusCodes;

/** 响应可接受的MIME类型。当不是 nil 时，响应带有 Content-Type 且MIME类型与集合不相交将在验证期间导致错误。
 */
@property (nonatomic, copy, nullable) NSSet <NSString *> *acceptableContentTypes;

/** 验证响应数据
 * 在基本实现中，该方法检查可接受的状态码和 Content-Type 。使用子类添加其他特定于域的检查。
 * @param response 待验证的响应
 * @param data 与 response 相关联的数据
 * @param error 验证响应数据时遇到的错误
 * @return 如果 response 有效返回YES ，否则为 NO；
 */
- (BOOL)validateResponse:(nullable NSHTTPURLResponse *)response
                    data:(nullable NSData *)data
                   error:(NSError * _Nullable __autoreleasing *)error;

@end

#pragma mark -


/** AFJSONResponseSerializer 用于验证和解析JSON格式的响应报文
 * 默认接受以下MIME类型：
 * <ul>
 *     <li> `application/json`  官方标准
 *     <li> `text/json`
 *     <li> `text/javascript`
 *  </ul>
 *
 * 在 RFC 7159 - Section 8.1 中， 规定JSON文本需要用UTF-8、UTF-16或UTF-32编码，默认编码为UTF-8。
 * NSJSONSerialization 支持上述编码，为了提高效率，建议使用UTF-8；使用不支持的编码将导致序列化错误。
 */
@interface AFJSONResponseSerializer : AFHTTPResponseSerializer

- (instancetype)init;

/** 读取响应 JSON 数据和创建Foundation对象的选项，默认 0
 * <ul>
 *     <li> NSJSONReadingMutableContainers 指定数组和字典作为可变对象创建
 *     <li> NSJSONReadingMutableLeaves 返回的JSON对象中字符串的值为NSMutableString
 *     <li> NSJSONReadingAllowFragments 允许 JSON 字符串最外层既不是NSArray也不是NSDictionary
 *  </ul>
 */
@property (nonatomic, assign) NSJSONReadingOptions readingOptions;

/**  是否从响应的JSON数据中删除带有 NSNull 值的键值对 ；默认为 NO
 */
@property (nonatomic, assign) BOOL removesKeysWithNullValues;

/** 创建具有指定读写选项的JSON序列化器
 * @param readingOptions 指定的JSON读取选项
 */
+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions;

@end

#pragma mark -

/** AFXMLParserResponseSerializer 验证 XML 格式的响应数据并解码为 NSXMLParser 对象
 * 默认接受以下MIME类型：
 * <ul>
 *     <li> `application/xml`  官方标准
 *     <li> `text/xml`  其他常用类型
 *  </ul>
 */
@interface AFXMLParserResponseSerializer : AFHTTPResponseSerializer

@end

#pragma mark -

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED

/** AFXMLDocumentResponseSerializer 验证 XML 格式的响应数据并解码为 NSXMLDocument 对象
 * 默认接受以下MIME类型：
 * <ul>
 *     <li> `application/xml`  官方标准
 *     <li> `text/xml`  其他常用类型
 *  </ul>
 */
@interface AFXMLDocumentResponseSerializer : AFHTTPResponseSerializer

- (instancetype)init;

/** 为 NSXMLDocument 设计的输入和输出选项，默认 0 ；
 * <ul>
 *     <li> NSXMLDocumentTidyHTML 输入类型(Input),在处理文档期间 NSXMLDocument 将HTML格式转为有效的 XHTML；
 *          为增加可读性，在 block-level 元素 <p>, <div>, <h1> 等结束标签前添加一个换行符，将字符串值 <br> <hr>转为换行符。
 *     <li> NSXMLDocumentTidyXML  输入类型(Input),在文档处理期间将格式错误的 XML 更改为有效的 XML；
 *          它消除了 pretty-printing 格式，如前导制表符。
 *     <li> NSXMLDocumentValidate 输入类型(Input), 根据文档的DTD(内部或外部)或XML Schema验证文档。
 *     <li> NSXMLDocumentXInclude 输入类型(Input),用引用的节点替换文档中的所有 XInclude 节点；
 *           XInclude 允许客户端在一个文档中包含另一部分XML文档。
 *     <li> NSXMLDocumentIncludeContentTypeDeclaration 输出类型(Output),在文档的输出中包含HTML或XHTML的内容类型声明。
 *  </ul>
 */
@property (nonatomic, assign) NSUInteger options;

/** 创建具有指定选项的XML文档序列化器
 * @param mask XML文档选项
 */
+ (instancetype)serializerWithXMLDocumentOptions:(NSUInteger)mask;

@end

#endif

#pragma mark -

/** AFPropertyListResponseSerializer 解析 plist 格式的报文数据
 * 默认情况下，它接受以下MIME类型: `application/x-plist`
 */
@interface AFPropertyListResponseSerializer : AFHTTPResponseSerializer

/** 初始化方法指定了content-type是"application/x-plist"，即只支持plist格式的报文数据
 */
- (instancetype)init;

/** 指定属性列表序列化格式
 * <ul>
 *     <li> NSPropertyListOpenStepFormat 指定从 OpenStep APIs 继承的ASCII属性列表格式
 *     <li> NSPropertyListXMLFormat_v1_0 指定XML属性列表格式
 *     <li> NSPropertyListBinaryFormat_v1_0 指定二进制属性列表格式
 *  </ul>
 */
@property (nonatomic, assign) NSPropertyListFormat format;

/** 属性列表只读选项
 * <ul>
 *     <li> NSPropertyListImmutable 使返回的属性列表包含不可变对象
 *     <li> NSPropertyListMutableContainers 返回的属性列表具有可变容器和不可变 leaves
 *     <li> NSPropertyListMutableContainersAndLeaves 返回的属性列表具有可变容器和leaves
 *  </ul>
 */
@property (nonatomic, assign) NSPropertyListReadOptions readOptions;

/** 创建并返回具有指定格式，读、写选项的属性列表序列化器
 * @param format 指定属性列表序列化格式
 * @param readOptions 属性列表只读选项
 */
+ (instancetype)serializerWithFormat:(NSPropertyListFormat)format
                         readOptions:(NSPropertyListReadOptions)readOptions;

@end

#pragma mark -

/** AFImageResponseSerializer ：验证和解码图片响应。
 * 默认情况下，它接受一下 MIME 类型，对应于 UIImage 或 NSImage 支持的图像格式:
 *  <ul>
 *     <li> `image/tiff`
 *     <li> `image/jpeg`
 *     <li> `image/gif`
 *     <li> `image/png`
 *     <li> `image/ico`
 *     <li> `image/x-icon`
 *     <li> `image/bmp`
 *     <li> `image/x-bmp`
 *     <li> `image/x-xbitmap`
 *     <li> `image/x-win-bitmap`
 *  </ul>
 */
@interface AFImageResponseSerializer : AFHTTPResponseSerializer

#if TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH

/** 图像比例在编码图像数据构造 responseImage 时使用；
 * 不同的 imageScale 将改变 UIImage.size ，将 imageScale 设置为 1.0 将得到一个 size 与像素相匹配的图像。
 * 默认值为 MainScreen.scale
 */
@property (nonatomic, assign) CGFloat imageScale;

/** 是否自动压缩响应的图像数据：如 PNG 或 JPEG 格式；默认值为 YES
 * 使用 -setCompletionBlockWithSuccess:failure: 可以显著提高iOS上的绘图性能，因为它允许在后台构建位图，而不是在主线程上
 */
@property (nonatomic, assign) BOOL automaticallyInflatesResponseImage;
#endif

@end

#pragma mark -

/** AFCompoundSerializer 支持服务器响应的多种数据类型和结构
 */
@interface AFCompoundResponseSerializer : AFHTTPResponseSerializer

/** 响应序列化器集合
 */
@property (readonly, nonatomic, copy) NSArray <id<AFURLResponseSerialization>> *responseSerializers;

/** 创建由指定响应序列化器组成的复合序列化器
 * @warning 这些响应序列化器必须是 AFHTTPResponseSerializer 的子类，以及响应方法 -validateResponse:data:error:
 */
+ (instancetype)compoundSerializerWithResponseSerializers:(NSArray <id<AFURLResponseSerialization>> *)responseSerializers;

@end

///----------------
/// @name 常量
///----------------

/** 预定义的错误域
 * 该错误域指定为 AFURLResponseSerializer 遇到的错误，错误码对应于 NSURLErrorDomain 中的错误码。
 */
FOUNDATION_EXPORT NSString * const AFURLResponseSerializationErrorDomain;

/** 上述指定错误域 NSError.userInfo 中指定的 key 键：
 * AFNetworkingOperationFailingURLResponseErrorKey： 值是与错误相关的 NSURLResponse
 * AFNetworkingOperationFailingURLResponseDataErrorKey： 值是与错误相关的原始数据 NSData
 */
FOUNDATION_EXPORT NSString * const AFNetworkingOperationFailingURLResponseErrorKey;
FOUNDATION_EXPORT NSString * const AFNetworkingOperationFailingURLResponseDataErrorKey;

NS_ASSUME_NONNULL_END
