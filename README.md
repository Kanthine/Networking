>  协议是指计算机通信网络中两台计算机之间进行通信所必须共同遵守的规定或规则。

#### 1、`HTTP` 协议

##### 1.1、 什么是 `HTTP` 协议？

超文本传输协议 `HTTP` 是一种通信协议:  一种详细规定了浏览器和万维网(`WWW = WorldWideWeb`)服务器之间互相通信的规则，用于从`WWW`服务器传输超文本到本地浏览器的数据传送协议。
* 它允许将超文本标记语言 `HTML` 从 `Web` 服务器传送到客户端的浏览器；
* 它可以使浏览器更加高效，使网络传输减少；
* 它不仅保证计算机正确快速地传输超文本文档，还确定传输文档中的哪一部分，以及哪部分内容首先显示(如文本先于图形)等。


##### 1.2、 `HTTP` 协议的发展

发展历史|产生时间|内容
:-:|:-:|-
`HTTP/0.9`|1991年|不涉及数据包传输，规定客户端和服务器之间通信格式，只能`GET`请求
`HTTP/1.0`|1996年|传输内容格式不限制，增加 `PUT、PATCH、HEAD、 OPTIONS、DELETE` 命令
`HTTP/1.1`|1997年|持久连接(长连接)、节约带宽、HOST域、管道机制、分块传输编码
`HTTP/2`|2015年|多路复用、服务器推送、头信息压缩、二进制协议等

`HTTP/0.9`和`HTTP/1.0`使用非持续连接：限制每次连接只处理一个请求，服务器处理完客户的请求，并收到客户的应答后，即断开连接。`HTTP/1.1`使用持续连接：不必为每个web对象创建一个新的连接，一个连接可以传送多个对象，采用这种方式可以节省传输时间。

![HTTP/2 ‘多路复用’的性能优势](https://upload-images.jianshu.io/upload_images/7112462-70c4c99b249a2dec.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


__多路复用__：通过单一的 `HTTP/2` 连接请求发起多个的请求-响应消息，多个请求流共享一个 `TCP` 连接，实现多留并行而非建立多个 `TCP` 连接。


##### 1.3、 `HTTP` 协议的特点

`HTTP` 协议是一个应用层协议，主要特点可概括如下：
* 基于请求和响应： `HTTP` 协议永远都是客户端发起请求，服务器回送响应。这样就限制了 `HTTP`协议的使用，无法实现在客户端没有发起请求的时候，服务器将消息推送给客户端。
* 灵活：`HTTP` 允许传输任意类型的数据对象；正在传输的类型由 `Content-Type` 加以标记。
* 无状态协议：协议对客户端没有状态存储，对事物处理没有“记忆”能力；比如访问一个网站需要反复进行登录操作，这样可能导致每次连接传送的数据量增大。
* 通信使用明文、请求和响应不会对通信方进行确认、无法保护数据的完整性。


###### 无状态协议

> 协议的状态是指下一次传输可以“记住”这次传输信息的能力。

`HTTP` 协议为了保证服务器内存，为了提高服务器对并发访问的处理能力；在服务器发送响应报文时，是不会为了下一次连接而维护这次连接所传输的信息。
这有可能出现一个浏览器在短短几秒之内两次访问同一对象时，服务器进程不会因为已经给它发过响应报文而不接受第二次请求。


##### `Connection` : `keep-alive`

`HTTP`是一个无状态的面向连接的协议，无状态不代表`HTTP`不能保持`TCP`连接，更不能代表`HTTP`使用的是`UDP`协议（无连接）。
从`HTTP/1.1` 起，默认都开启了 `Keep-Alive` ，保持连接特性，简单地说，当一个网页打开完成后，客户端和服务器之间用于传输`HTTP`数据的`TCP`连接不会关闭，如果客户端再次访问这个服务器上的网页，会继续使用这一条已经建立的连接。
`Keep-Alive` 不会永久保持连接，它有一个保持时间，可以在不同的服务器软件中设定这个时间。


##### 1.4、 `HTTP` 协议通信流程

![HTTP通信流程](https://upload-images.jianshu.io/upload_images/7112462-30b19737c05db342.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


一次 `HTTP`  操作称为一个事务，其工作过程可分为四步：
* step1：首先客户端与服务器需要建立 `TCP` 连接；只要单击某个链接， `HTTP`  的工作开始。
* step2：建立 `TCP` 连接后，客户端发送请求报文给服务器；请求报文有四大部分：请求行、请求头、空行、请求数据。
* step3：服务器接到请求后，给予相应的响应报文；响应报文有三大部分：状态行、消息报头、响应正文。
* step4：客户端接收服务器返回的数据后，根据 `Connection` 信息决定是否断开 `TCP` 连接。

如果在以上过程中的某一步出现错误，那么产生错误的信息将返回到客户端。

###### 1.4.1、建立 `TCP` 连接，为什么需要三次握手呢？

为了防止已失效的连接请求报文突然传送到了服务端，因而产生错误。比如：

* 客户端发出的第一个连接请求报文段并没有丢失，而是在某个网络结点长时间的滞留了，以致延误到连接释放以后的某个时间才到达服务器。
* 本来这是一个早已失效的报文段，但是服务器收到此失效的连接请求报文段后，就误认为是客户端再次发出的一个新的连接请求，于是就向客户端发出确认报文段，同意建立连接。
* 假设不采用“三次握手”，那么只要服务器发出确认，新的连接就建立了，由于客户端并没有发出建立连接的请求，因此不会理睬服务器的确认，也不会向服务器发送请求数据，但服务器却以为新的运输连接已经建立，并一直等待客户端发来数据。
* 所以没有采用“三次握手”，这种情况下服务器的很多资源就白白浪费掉了。


#### 2、`HTTPS` 协议

> `HTTPS` 协议 =  `HTTP` 协议 + `SSL/TLS` 协议

`HTTPS` 是一种通过计算机网络进行安全通信的传输协议，经由`HTTP` 进行通信，利用 `SSL/TLS `在不安全的网络上创建一个安全通道，加密数据包，对窃听和中间人攻击提供一定程度的合理防护。
使用`HTTPS` 的主要目的是提供对网站服务器的身份认证，同时保护交换数据的隐私与完整性。

#####  `HTTPS` 协议的特点

* 基于 `HTTP` 协议，通过 `SSL\TLS` 提供加密处理数据、验证对方身份以及数据完整性保护；
* 内容加密：采用混合加密技术，中间者无法直接查看明文内容；
* 验证身份：通过证书认证客户端与服务器的身份，辨别中间人；
* 保护数据完整性：防止传输的内容被中间人冒充或者篡改；

##### 2.1、 对称加密与非对称加密

一些密码学的名词：
* 明文：未被加密过的原始数据。
* 密文：明文被某种加密算法加密之后，会变成密文，从而确保原始数据的安全。密文也可以被解密，得到原始的明文。
* 密钥：密钥是一种参数，它是在明文转换为密文或将密文转换为明文的算法中输入的参数。密钥分为对称密钥与非对称密钥，分别应用在对称加密和非对称加密上。

###### 2.1.1、 对称加密

对称加密又叫做私钥加密，即信息的发送方和接收方使用同一个密钥去加密和解密数据。(私钥表示个人私有的密钥，即该密钥不能被泄露。)

加密过程如下：`明文 + 加密算法 + 私钥 -> 密文`
解密过程如下：`密文 + 解密算法 + 私钥 -> 明文`

对称加密的特点是算法公开、加密和解密速度快，适合于对大数据量进行加密；但私钥泄露，密文很容易就被破解，所以对称加密的缺点是密钥安全管理困难。

常见的对称加密算法有DES、3DES、TDEA、Blowfish、RC5和IDEA。

###### 2.1.2、 非对称加密

非对称加密也叫做公钥加密：使用公钥和私钥，且二者成对出现。私钥被自己保存，不能对外泄露；公钥指的是公共的密钥，任何人都可以获得该密钥。用公钥或私钥中的任何一个进行加密，用另一个进行解密。

被公钥加密过的密文只能被私钥解密，过程如下：
```
明文 + 加密算法 + 公钥 -> 密文 
密文 + 解密算法 + 私钥 -> 明文
```

被私钥加密过的密文只能被公钥解密，过程如下：
```
明文 + 加密算法 + 私钥 -> 密文
密文 + 解密算法 + 公钥 -> 明文
```

由于加密和解密使用了两个不同的密钥，相对于对称加密，非对称加密安全性更好。但非对称加密的缺点是加密和解密花费时间长、速度慢，只适合对少量数据进行加密。

在非对称加密中使用的主要算法有：RSA、Elgamal、Rabin、D-H、ECC（椭圆曲线加密算法）等。

##### 2.2、 `HTTPS` 协议通信流程

`HTTPS` 协议如果使用对称加密，私钥的管理是个问题；但如果使用非对称加密，花费时间长且速度慢。
为避免上述问题，`HTTPS`  使用非对称加密与对称加密相结合的方式，第一次通信时，使用非对称加密将“对称加密的私钥”传递给对方；之后通信时，使用“对称加密的私钥”加密与解密数据。

![HTTPS协议通信（非对称加密与对称加密相结合）](https://upload-images.jianshu.io/upload_images/7112462-b927e94aebb0e402.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


一个 `HTTPS` 请求可以细分为8步：
* step1 客户端向服务器发起 `HTTPS` 请求，连接到服务器的443端口。
* step2 服务端有一对用来非对称加密的公匙与密钥；私钥由服务器端保存，不能将其泄露，公钥可以发送给任何人。
* step3 服务器将自己的公钥发送给客户端。
* step4 客户端收到服务器端的公钥之后；创建一个随机值，这个随机值就是对称加密的私钥（客户端密钥 `client key`）。然后用服务器的公钥对客户端密钥进行非对称加密，这样客户端密钥就变成密文了。
* step5 客户端将加密之后的客户端密钥发送给服务器。
* step6 服务器接收到客户端发来的密文之后，会用自己的私钥对其进行非对称解密，解密之后的明文就是客户端密钥，然后用客户端密钥对数据进行对称加密，这样数据就变成了密文。
* step7 然后服务器将加密后的密文发送给客户端。
* step8 客户端收到服务器发送来的密文，用客户端密钥对其进行对称解密，得到服务器发送的数据，至此整个 `HTTPS` 传输完成。

##### 2.4、被拦截的公钥

假如有一个中间人，拦截服务器的公匙，并向客户端伪造公匙，那么依旧可以获取并伪造通信内容！

![中间人伪造的公钥](https://upload-images.jianshu.io/upload_images/7112462-c1c61784b3310f85.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


在上述过程中，客户端与服务端，均不知道他们的通信被中间人拦截了。怎么才能避免中间人拦截呢？？可以要求客户端对公匙的来源做一个合法性的校验，保证客户端收到的公钥是服务端的公钥，而不是中间人伪造的公钥！！

合法性的校验，也就是客户端和服务器，都需要一个值得信任的公证人！将服务器的公匙交给公证人，由公证人颁布一个证书，证书包含公钥以及身份信息，客户端通过验证证书的合法性来确保公匙来自于服务端。（所谓的公证人也就是证书颁发机构）

> 证书是用来认证公钥持有者身份的电子文档，防止第三方进行冒充。一个证书中包含了公钥、持有者信息、证明证书内容有效的签名以及证书有效期，还有一些其他额外信息。

##### 2.5、数字证书

数字证书通常来说是由受信任的数字证书颁发机构CA，在验证服务器身份后颁发。
证书颁发者在得到服务端的一些必要信息（身份信息，公钥私钥、服务器域名）之后，通过 `SHA-256` 哈希得到证书内容的摘要，再用自己的私钥给这份摘要加密，得到数字签名。综合已有的信息，生成分别包含公钥和私钥的两个证书。

数字证书被放到服务端，具有服务器身份验证和数据传输加密功能。

###### 2.5.1、证书链

数字证书的生成是分层级的，下一级的证书需要其上一级证书的私钥签名；也就是证书由颁发者的私钥签名。

###### 2.5.2、数字证书的安全问题

![生成证书](https://upload-images.jianshu.io/upload_images/7112462-7a8f95b7a0c03409.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


__如何确保证书颁发机构颁布的证书不被拦截篡改呢？__
* 1、证书颁发机构用数字摘要算法，将公钥和身份信息生成一个 _摘要_；
* 2、证书颁发机构使用非对称加密算法把对摘要进行加密，生成 _数字签名_；
* 3、证书颁发机构将 _公钥和身份信息_ 与 _数字签名_ 合并，形成 _数字证书_ ；
* 4、服务器将数字证书发送给客户端；
* 5、客户端获得数字证书，使用 _证书颁发者的公钥_  进行解密生成摘要信息；再用数字摘要算法对 _证书中的公钥_ 和身份信息生成摘要信息，两者比对，如果能匹配，就说明数字证书没有被篡改，公匙来自于服务端；


![验证证书](https://upload-images.jianshu.io/upload_images/7112462-b82f37a89d9d5fa0.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


###### 2.5.3、证书颁发机构的信任问题

采用数字证书方式是为了解决公钥传输的中间人攻击问题，假如证书颁发机构的公钥传输也出现中间人攻击问题，那么问题死循环了？

可以把证书颁发者的公钥预先加载在操作系统中！如果操作系统和浏览器的公钥也被篡改，那就没招了。所以不要轻易信任安装未知证书。

> 苹果、微软等公司会根据一些权威安全机构的评估选取一些信誉很好并且通过一定的安全认证的证书发布机构，把这些证书发布机构的证书默认安装在操作系统中，并且设置为操作系统信任的数字证书。


##### 2.6、证书认证的`HTTPS` 协议通信流程

![证书认证的通信](https://upload-images.jianshu.io/upload_images/7112462-3744ad1cefc68336.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



#### 3、请求报文与响应报文

HTTP有两类报文：
* 请求报文：由请求行（request line）、请求头部（header）、空行和请求数据4个部分组成。
* 响应报文：由状态行、消息报头、响应正文三个部分组成。


##### 3.1、请求报文

请求报文
* 请求行：由请求方法、URL 和 HTTP协议版本 3 个字段组成，它们用空格分隔。例如，GET /index.html HTTP/1.1。
* 请求头：通知服务器有关于客户端请求的信息；由键/值对组成。
* 空  行：最后一个请求头之后是一个空行，发送回车符和换行符，通知服务器以下不再有请求头。
* 请求数据：请求数据不在GET方法中使用，而是在POST方法中使用。

###### 3.1.1、请求方法

`HTTP/1.1` 协议中共定义了八种方法来表明 `Request-URI` 指定的资源的不同操作方式：

* `OPTIONS`：返回服务器针对特定资源所支持的HTTP请求方法。也可以利用向服务器发送 `*` 的请求来测试服务器的功能性。
* `HEAD`：向服务器索要与 `GET` 请求相一致的响应，只不过响应体将不会被返回。这一方法可以在不必传输整个响应内容的情况下，就可以获取包含在响应消息头中的元信息。该方法常用于测试超链接的有效性，是否可以访问，以及最近是否更新。
* `GET` ：向特定的资源发出请求。
* `POST`：向指定资源提交表单或者上传文件等；数据被包含在请求体中。`POST` 请求可能会导致新的资源的建立和/或已有资源的修改。
* `PUT`：向指定资源位置上传其最新内容。
* `DELETE`：请求服务器删除 `Request-URI` 所标识的资源。
* `TRACE`：回显服务器收到的请求，主要用于测试或诊断。
* `CONNECT`：`HTTP/1.1` 协议中预留给能够将连接改为管道方式的代理服务器。
* `PATCH`：用来将局部修改应用于某一资源，添加于规范 `RFC5789`。

###### 3.1.2、`GET` 与  `POST`的区别

区别|`GET` |`POST`
-|-|-
提交数据|放在`URL`之后，以`?`分割 `URL` 和传输数据，参数之间以`&` 相连，如 `EditPosts.aspx?name=test1&id=123456` | 把提交的数据放在 `HTTP` 包的 `Body` 中
大小限制|最多只能有1024字节的数据|没有限制
获取变量|使用`Request.QueryString`来取得变量的值|通过`Request.Form`来获取变量的值
安全性|比如一个登录页面，用户名和密码将出现在URL上，如果页面可以被缓存或者其他人可以访问这台机器，就可以从历史记录获得该用户的账号和密码|在请求体中，相对安全


##### 3.2、响应报文

响应报文
* 状态行：通过提供一个状态码来说明所请求的资源情况。`HTTP-Version Status-Code Reason-Phrase CRLF`
* 消息报头：通知客户端有关于服务器请求的信息；由键/值对组成。
* 响应正文：


##### 3.3、常见的请求头


###### 3.3.1、缓存相关


`If-Modified-Since`：把客户端缓存数据页面的最后修改时间发送到服务器去，服务器会把这个时间与服务器上实际文件的最后修改时间进行对比。如果时间一致，那么返回 `304` ，客户端就直接使用本地缓存文件。如果时间不一致，就会返回 `200` 和新的文件内容。客户端接到之后，会丢弃旧文件，把新文件缓存起来。

```
If-Modified-Since: Thu, 09 Feb 2012 09:07:57 GMT
```


`If-None-Match`：和`ETag`一起工作，工作原理是在 `HTTP Response` 中添加 `ETag`信息。 当用户再次请求该资源时，将在`HTTP Request` 中加入`If-None-Match`信息(`ETag`的值)。如果服务器验证资源的`ETag`没有改变（该资源没有更新），将返回一个`304`状态告诉客户端使用本地缓存文件。否则将返回`200`状态和新的资源和`Etag`.  使用这样的机制将提高网站的性能。

```
If-None-Match: "03f2b33c0bfcc1:0"。
```

`Pragma`：指定 `no-cache` 值表示服务器必须返回一个刷新后的文档，即使它是代理服务器而且已经有了页面的本地拷贝；在`HTTP/1.1`版本中，它和`Cache-Control:no-cache`作用一模一样。`Pargma`只有一个用法， 例如： `Pragma: no-cache`
注意: 在`HTTP/1.0`版本中，只实现了`Pragema:no-cache`, 没有实现`Cache-Control`。


`Cache-Control`：指定请求和响应遵循的缓存机制。缓存指令是单向的（响应中出现的缓存指令在请求中未必会出现），且是独立的（在请求报文或响应报文中设置`Cache-Control` 并不会修改另一个消息处理过程中的缓存处理过程）。请求报文的缓存指令包括`no-cache`、`no-store`、`max-age`、`max-stale`、`min-fresh`、`only-if-cached`，响应报文中的指令包括`public`、`private`、`no-cache`、`no-store`、`no-transform`、`must-revalidate`、`proxy-revalidate`、`max-age`、`s-maxage`。

* `Cache-Control:no-cache`： 所有内容都不会被缓存
* `Cache-Control:no-store`： 用于防止重要的信息被无意的发布。在请求报文中发送将使得请求和响应文中都不使用缓存。
* `Cache-Control:Public` 可以被任何缓存所缓存
* `Cache-Control:Private` 内容只缓存到私有缓存中
* `Cache-Control:max-age` 指示客户端可以接收生存期不大于指定时间（以秒为单位）的响应。
* `Cache-Control:min-fresh` 指示客户端可以接收响应时间小于当前时间加上指定时间的响应。
* `Cache-Control:max-stale` 指示客户端可以接收超出超时期间的响应消息。如果指定`max-stale`消息的值，那么客户端可以接收超出超时期指定值之内的响应消息。


###### 3.3.2、接收的数据限制

`Accept`：客户端可以接受的`MIME`类型；例如：`Accept: text/html` 代表客户端可以接受服务器回发的类型为 `text/html` 也就是`html`文档，如果服务器无法返回`text/html`类型的数据，服务器应该返回一个`406`错误(`non acceptable`)。通配符 * 代表任意类型，例如 `Accept: */*` 代表客户端可以处理所有类型。

`Accept-Encoding`：客户端申明自己可接收的编码方法，通常指定压缩方法，是否支持压缩，支持什么压缩方法（`gzip`，`deflate`）;`Servlet` 能够向支持`gzip` 的客户端返回经`gzip`编码的 `HTML` 页面。许多情形下这可以减少5到10倍的下载时间。例如： `Accept-Encoding: gzip`。如果请求消息中没有设置这个域，服务器假定客户端对各种内容编码都可以接受。

`Accept-Language`：客户端申明自己接收的语言；例如：`Accept-Language: en-us`。如果请求消息中没有设置这个报头域，服务器假定客户端对各种语言都可以接受。

`Accept-Charset`：客户端可接受的字符集，中文有多种字符集，比如`big5、gb2312、gbk`等等。如果在请求消息中没有设置这个域，缺省表示任何字符集都可以接受。

`Content-Type`：具体请求中的数据类型；例如：`Content-Type: application/x-www-form-urlencoded`。
`Content-Length`：表示请求消息正文的长度。例如：`Content-Length: 38`。


###### 3.3.3、`HTTP 1.1`之后是否进行持久连接？

`Connection: keep-alive` 当一个网页打开完成后，客户端和服务器之间用于传输`HTTP`数据的`TCP`连接不会关闭，如果客户端再次访问这个服务器上的网页，会继续使用这一条已经建立的连接。`HTTP 1.1`默认进行持久连接。利用持久连接的优点，当加载多个图片时，显著地减少下载所需要的时间。要实现这一点，服务器需要在应答中发送一个`Content-Length`头，最简单的实现方法是：先把内容写入`ByteArrayOutputStream`，然后在正式写出内容之前计算它的大小。
`Connection: close` 代表一个`Request` 完成后，客户端和服务器之间用于传输`HTTP`数据的`TCP`连接会关闭，当客户端再次发送`Request`，需要重新建立TCP连接。

###### 3.3.4、分段下载

`Range:bytes=start-end`：可以请求实体的一个或者多个子范围，用于大文件的分段下载：
* `Range:bytes=0-499`：表示前500个字节；
* `Range:bytes=500-999`：表示第二个500字节；
* `Range:bytes=-500`：表示最后500个字节；
* `Range:bytes=500-`：表示500字节以后的范围；
* `Range:bytes=0-0,-1`：第一个和最后一个字节；

同时指定几个范围：`Range:bytes=500-600,601-999`。
服务器可以忽略此请求头，如果无条件`GET`包含`Range`请求头，响应会以状态码`206`（`PartialContent`）返回而不是以`200`（`OK`）。


###### 3.3.5、其它字段


`User-Agent`：告诉服务器，客户端使用的操作系统和App的名称和版本。
例如：`User-Agent:objective-c-language/1.0 (iPhone; iOS 10.3.3; Scale/2.00)`

`Cookie`：最重要的请求头之一, 将客户端的`cookie`值发送给`HTTP`服务器。

`Authorization`：授权信息，通常出现在对服务器发送的`WWW-Authenticate`头的应答中，用base64将用户名和密码编码，用于证明客户端是否有权查看某个资源。当客户端发起一个请求时，如果收到服务器的响应代码为`401`（未授权），可以发送一个包含`Authorization`请求报头域的请求，要求服务器对其进行验证。
例如：`Authorization:MTM4MDAwMDAwMDA6YTEyMzQ1Njc`


`Referer`：包含一个`URL`，用户从该`URL`代表的页面出发访问当前请求的页面。提供了`Request`的上下文信息的服务器，告诉服务器我是从哪个链接过来的，比如从我主页上链接到一个朋友那里，他的服务器就能够从`HTTP Referer`中统计出每天有多少用户点击我主页上的链接访问他的网站。
例如:` Referer:http://translate.google.cn/?hl=zh-cn&tab=wT`


`Host`：（发送请求时，该头域是必需的）主要用于指定被请求资源的Internet主机和端口号，它通常从HTTP URL中提取出来的。HTTP/1.1请求必须包含主机头域，否则系统会以400状态码返回。
例如: 我们在浏览器中输入：http://www.guet.edu.cn/index.html，浏览器发送的请求消息中，就会包含Host请求头域：Host：http://www.guet.edu.cn，此处使用缺省端口号80，若指定了端口号，则变成：Host：指定端口号。


##### 3.5、常见的响应头

Allow：服务器支持哪些请求方法（如GET、POST等）。

Date：表示消息发送的时间，时间的描述格式由rfc822定义。例如，Date:Mon,31Dec200104:25:57GMT。Date描述的时间表示世界标准时，换算成本地时间，需要知道用户所在的时区。你可以用setDateHeader来设置这个头以避免转换时间格式的麻烦

Expires：指明应该在什么时候认为文档已经过期，从而不再缓存它，重新从服务器获取，会更新缓存。过期之前使用本地缓存。HTTP1.1的客户端和缓存会将非法的日期格式（包括0）看作已经过期。eg：为了让浏览器不要缓存页面，我们也可以将Expires实体报头域，设置为0。
例如: Expires: Tue, 08 Feb 2022 11:35:14 GMT

P3P：用于跨域设置Cookie, 这样可以解决iframe跨域访问cookie的问题
例如: P3P: CP=CURa ADMa DEVa PSAo PSDo OUR BUS UNI PUR INT DEM STA PRE COM NAV OTC NOI DSP COR

Set-Cookie：非常重要的header, 用于把cookie发送到客户端浏览器，每一个写入cookie都会生成一个Set-Cookie。
例如: Set-Cookie: sc=4c31523a; path=/; domain=.acookie.taobao.com

ETag：和If-None-Match 配合使用。

Last-Modified：用于指示资源的最后修改日期和时间。Last-Modified也可用setDateHeader方法来设置。


Content-Type：WEB服务器告诉浏览器自己响应的对象的类型和字符集。Servlet默认为text/plain，但通常需要显式地指定为text/html。由于经常要设置Content-Type，因此HttpServletResponse提供了一个专用的方法setContentType。可在web.xml文件中配置扩展名和MIME类型的对应关系。
例如:Content-Type: text/html;charset=utf-8
　　 Content-Type:text/html;charset=GB2312
　　 Content-Type: image/jpeg

媒体类型的格式为：大类/小类，比如text/html。
IANA(The Internet Assigned Numbers Authority，互联网数字分配机构)定义了8个大类的媒体类型，分别是:
application— (比如: application/vnd.ms-excel.)
audio (比如: audio/mpeg.)
image (比如: image/png.)
message (比如,:message/http.)
model(比如:model/vrml.)
multipart (比如:multipart/form-data.)
text(比如:text/html.)
video(比如:video/quicktime.)

Content-Range：用于指定整个实体中的一部分的插入位置，他也指示了整个实体的长度。在服务器向客户返回一个部分响应，它必须描述响应覆盖的范围和整个实体长度。一般格式：Content-Range:bytes-unitSPfirst-byte-pos-last-byte-pos/entity-length。
例如，传送头500个字节次字段的形式：Content-Range:bytes0-499/1234如果一个http消息包含此节（例如，对范围请求的响 应或对一系列范围的重叠请求），Content-Range表示传送的范围。


Content-Length：指明实体正文的长度，以字节方式存储的十进制数字来表示。在数据下行的过程中，Content-Length的方式要预先在服务器中缓存所有数据，然后所有数据再一股脑儿地发给客户端。只有当浏览器使用持久HTTP连接时才需要这个数据。如果你想要利用持久连接的优势，可以把输出文档写入ByteArrayOutputStram，完成后查看其大小，然后把该值放入Content-Length头，最后通过byteArrayStream.writeTo(response.getOutputStream()发送内容。
例如: Content-Length: 19847

Content-Encoding：WEB服务器表明自己使用了什么压缩方法（gzip，deflate）压缩响应中的对象。只有在解码之后才可以得到Content-Type头指定的内容类型。利用gzip压缩文档能够显著地减少HTML文档的下载时间。Java的GZIPOutputStream可以很方便地进行gzip压缩，但只有Unix上的Netscape和Windows上的IE 4、IE 5才支持它。因此，Servlet应该通过查看Accept-Encoding头（即request.getHeader("Accept-Encoding")）检查浏览器是否支持gzip，为支持gzip的浏览器返回经gzip压缩的HTML页面，为其他浏览器返回普通页面。
例如：Content-Encoding：gzip

Content-Language：WEB服务器告诉浏览器自己响应的对象所用的自然语言。例如： Content-Language:da。没有设置该域则认为实体内容将提供给所有的语言阅读。

Server：指明HTTP服务器用来处理请求的软件信息。例如：Server: Microsoft-IIS/7.5、Server：Apache-Coyote/1.1。此域能包含多个产品标识和注释，产品标识一般按照重要性排序。

X-AspNet-Version：如果网站是用ASP.NET开发的，这个header用来表示ASP.NET的版本。
例如: X-AspNet-Version: 4.0.30319

X-Powered-By：表示网站是用什么技术开发的。
例如： X-Powered-By: ASP.NET

Connection：
例如：Connection: keep-alive 当一个网页打开完成后，客户端和服务器之间用于传输HTTP数据的TCP连接不会关闭，如果客户端再次访问这个服务器上的网页，会继续使用这一条已经建立的连接。
Connection: close 代表一个Request完成后，客户端和服务器之间用于传输HTTP数据的TCP连接会关闭，当客户端再次发送Request，需要重新建立TCP连接。

Location：用于重定向一个新的位置，包含新的URL地址。表示客户应当到哪里去提取文档。Location通常不是直接设置的，而是通过HttpServletResponse的sendRedirect方法，该方法同时设置状态代码为302。Location响应报头域常用在更换域名的时候。

Refresh：表示浏览器应该在多少时间之后刷新文档，以秒计。除了刷新当前文档之外，你还可以通过setHeader("Refresh", "5; URL=http://host/path")让浏览器读取指定的页面。注意这种功能通常是通过设置HTML页面HEAD区的<META HTTP-EQUIV="Refresh" CONTENT="5;URL=http://host/path">实现，这是因为，自动刷新或重定向对于那些不能使用CGI或Servlet的HTML编写者十分重要。但是，对于Servlet来说，直接设置Refresh头更加方便。注意Refresh的意义是“N秒之后刷新本页面或访问指定页面”，而不是“每隔N秒刷新本页面或访问指定页面”。因此，连续刷新要求每次都发送一个Refresh头，而发送204状态代码则可以阻止浏览器继续刷新，不管是使用Refresh头还是<META HTTP-EQUIV="Refresh" ...>。注意Refresh头不属于HTTP 1.1正式规范的一部分，而是一个扩展，但Netscape和IE都支持它。

WWW-Authenticate：该响应报头域必须被包含在401（未授权的）响应消息中，客户端收到401响应消息时候，并发送Authorization报头域请求服务器对其进行验证时，服务端响应报头就包含该报头域。
eg：WWW-Authenticate:Basic realm="Basic Auth Test!" //可以看出服务器对请求资源采用的是基本验证机制。




疑问：HTTPS 实现传输安全的关键是：在 TLS/SSL 握手阶段保证仅有通信双方得到 Session Key ？

----

参考文章：

[HTTP协议详解](https://www.cnblogs.com/EricaMIN1987_IT/p/3837436.html)
[HTTPS协议](https://blog.csdn.net/xiaoming100001/article/details/81109617)
[Https原理及流程](https://www.jianshu.com/p/14cd2c9d2cd2)
[HTTPS安全通信过程](https://www.cnblogs.com/xtiger/p/11026870.html)
[客户端认证https服务端证书过程:证书链](https://blog.csdn.net/huzhenv5/article/details/104578198)
