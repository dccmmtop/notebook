---
title: openVpn
date: 2021-10-14 17:11:07
---


## VPN 的作用
vpn通常拿来做2个事情，
* 一个是可以让世界上任意2台机器进入一个虚拟的局域网中，这个局域网的数据通讯是加密的，很安全，用起来和一个家庭局域网没有区别
## 原理
vpn比ss更加底层，它通过操作系统的接口直接虚拟出一张网卡，后续整个操作系统的网络通讯都将通过这张虚拟的网卡进行收发。这和任何一个代理的实现思路都差不多，应用层并不知道网卡是虚拟的，这样vpn虚拟网卡将以中间人的身份对数据进行加工，从而实现各种神奇的效果。具体来说，vpn是通过编写一套网卡驱动并注册到操作系统实现的虚拟网卡，这样数据只要经过网卡收发就可以进行拦截处理。

vpn在IP层工作，而ss在TCP层工作。

![](../images/20211017101733685_29378.png =1086x)

1. 在服务端安装 vpn server 在客户端安装 vpn client,确保客户端和vpn Server 的网络是通的
2. 在服务端和客户端机器上会虚拟出一张网卡，分配的ip地址是 10.8.1.4 和 10.8.1.3,仿佛在同一个局域网内
   ```conf
   ##设定server端虚拟出来的网段，设置给客户端虚拟局域网的网段
   server 10.8.0.0 255.255.255.0
   ```
3. 服务端或客户端有配置文件可以指定当客户端访问哪些ip时，通过vpn 途径。哪些ip走客户端由真实网卡发出去
   ```conf
   ##通过VPN Server往Client push路由，client通过pull指令获得Server push的所有选项并应用
   push "route 40.18.14.9 255.255.255.255"
   ```
4. 假设现有配置使的客户端访问 40.18.14.9 IP时，走vpn途径
5. 客户端访问 40.18.14.9 时，根据配置由 vpn client 接管，将客户端IP 改成 10.8.1.3，将数据发送给 vpn server
6. vpn server 虚拟网卡D 接收数据后，将将数据发给 应用服务器E,由于 虚拟网卡D 和 应用服务器E 不通，需要添加一个路由规则，将在来源 10.8.1.3的数据由真实网卡C转发。通常由 iptables 或者 firewalls 服务实现改路由规则
   ```conf
   iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE 
   ```
7. 数据至此从客户端发给应用服务器。在 客户端到vpn server 传输过程中，均是加密的。


## OpenVPN的优点
- OpenVPN 是一个基于 OpenSSL 库的应用层 VPN 实现。和传统 VPN 相比，它的优点是简单易用。
- OpenVPN提供了多种身份验证方式，包括：预享私钥，第三方证书以及用户名/密码组合。预享密钥最为简单，但同时它只能用于建立点对点的VPN；
- 基于PKI的第三方证书提供了最完善的功能，但是需要额外的精力去维护一个PKI证书体系。
- OpenVPN2.0后引入了用户名/口令组合的身份验证方式，它可以省略客户端证书，但是仍有一份服务器证书需要被用作加密。
- OpenVPN所有的通信都基于一个单一的IP端口，默认且推荐使用UDP协议通讯，同时TCP也被支持。
- OpenVPN连接能通过大多数的代理服务器，并且能够在NAT的环境中很好地工作。
- 服务端具有向客户端“推送”某些网络配置信息的功能，这些信息包括：IP地址、路由设置等。
- OpenVPN提供了两种虚拟网络接口：通用Tun/Tap驱动，通过它们，可以建立三层IP隧道，或者虚拟二层以太网，后者可以传送任何类型的二层以太网络数据。
- 传送的数据可通过LZO算法压缩。在选择协议时候，需要注意2个加密隧道之间的网络状况，如有高延迟或者丢包较多的情况下，请选择TCP协议作为底层协议，UDP协议由于存在无连接和重传机制，导致要隧道上层的协议进行重传，效率非常低下。
IANA（Internet Assigned Numbers Authority）指定给OpenVPN的官方端口为1194。

## 安装openvpn
经测测试， centos 6.x 无法安装 openvpn 2.4 以上的版本，笔者选择的说是 2.2.0
[官方地址](https://openvpn.net/community-downloads/)笔者选择 源码安装
openvpn 依赖lzo,需要先安装 lzo, [下载地址](https://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz)
#### 安装脚本
```shell
tar -xzvf lzo-2.10.tar.gz
cd lzo-2.10
./configure --prefix=$HOME/opt/lzo-2.10 &&  make && make install
cd ../
tar -xzvf openvpn-2.2.0.tar.gz
cd openvpn-2.2.0
## 不使用lzo
##/configure --prefix=/home/dccmmtop/opt/openvpn-2.2.0  --disable-lzo
## 2.4 以后版本指定lzo
##./configure --prefix=$HOME/opt/openvpn-test1 LZO_LIBS="-L$HOME/opt/lzo-2.10/lib -llzo2" LZO_CFLAGS="-I$HOME/opt/lzo-2.10/include"

./configure --prefix=$HOME/opt/openvpn --with-lzo-lib="$HOME/opt/lzo-2.10/lib" --with-lzo-headers="$HOME/opt/lzo-2.10/include"
make && make install
cd ../
rm -rf lzo-2.10
rm -rf openvpn-2.2.0

if [ -x "$HOME/opt/openvpn/sbin/openvpn" ]; then
	echo "安装成功: $HOME/opt/openvpn/sbin/openvpn"
else
	echo "安装失败"
fi

```
## PKI
Public Key Infrastructure（PKI)，中文叫做公开密钥基础设施，也就是利用公开密钥机制建立起来的基础设施。

PKI的核心是身份证明书的发行
PKI的世界里，这个身份证明书，被叫做“证明书”。发行“证明书”的机关叫做“认证机关”。还有一个就是统一管理证明书的证书“档案库/证书库”。这三个东西加起来，就是PKI的主要构成要素。
证明书是被存放在硬盘或者IC卡里面的。证明书的文件构造是一种叫做 X.509 的协议规定的。另一方面，认证机关也其实就是一个网络应用程序。
PKI提供的证明书可以用来 身份确认 和 通信加密。
用“证明书中的密钥”加密过的内容，只能用自己才有的另一个“私人的密钥”才能解密。这样的话，如果你发送给自己的内容被他人窃取的话，他人也无法解密。
在PKI机制中，放在“证明书里面的密钥”可以被任意自由分发，这里的“证明书里的密钥”被叫做“公开密钥（Public Key）”。与此相对，本人保管的那个“私人的密钥”就要做“私有密钥（Private Key）”。
认证机关的可信度，直接与证书的可信度挂钩，也就是与整个PKI机制的可信度息息相关。
在技术上，伪造证明书是非常简单的。所谓假的证明书，比如说有一个所谓的“比尔的证明书”，但是里面含有的公开密钥是史提芬的公开密钥。那么，别人发给比尔的信息，史蒂芬可以解密，反而比尔自己不能解密。

## 生成服务端客户端证书
本文选择使用 easyras 生成证书
[仓库地址](https://github.com/OpenVPN/easy-rsa/releases)
根据自己的信息修改项目中的 vars.example 如下图：
![](../images/20211017170032306_32170.png)
证书生成脚本

```shell
openvpn=$HOME/opt/openvpn/sbin/openvpn
if [ ! -d "$openvpn" ]; then
  echo "没有安装openvpn, 请先执行 installOpenvpn 脚本"
  exit 1
fi
## 创建安装目录和配置文件目录
vpnDir=$HOME/opt/openvpn_config
mkdir -p $vpnDir/server
mkdir -p $vpnDir/client


## 安装 easyRsa
unzip EasyRSA-3.0.8.zip
cd EasyRSA-3.0.8
cp ../vars ./
##  生成公钥
chmod +x ./easyrsa
./easyrsa init-pki
./easyrsa build-ca nopass

## 生成服务器私钥和请求
./easyrsa gen-req yuanxin nopass
## 拷贝服务器私钥文件到配置文件目录下
cp ./pki/private/yuanxin.key $vpnDir/server

## 生成服务器证书
mv pki/reqs/yuanxin.req pki/reqs/yuanxinServer.req
./easyrsa import-req pki/reqs/yuanxinServer.req yuanxin
./easyrsa sign-req server yuanxin
cp pki/ca.crt pki/issued/yuanxin.crt $vpnDir/server

## 生成加密文件
./easyrsa gen-dh
$openvpn --genkey --secret ta.key
cp ta.key pki/dh.pem $vpnDir/server


## 生成客户端私钥和请求
./easyrsa gen-req yuanxinClient nopass
mv pki/reqs/yuanxinClient.req pki/reqs/yuanxinClient2.req
./easyrsa import-req pki/reqs/yuanxinClient2.req yuanxinClient
./easyrsa sign-req client yuanxinClient
cp pki/private/yuanxinClient.key pki/issued/yuanxinClient.crt ta.key pki/ca.crt $vpnDir/client

cd ../ && rm -rf EasyRSA-3.0.8/
```

## 服务端配置
```conf
dev tun
tls-server

## 监听的端口号，默认1194，如果要改的话防火墙也要相应修改。（可选） 
##port 1194 
##TCP或UDP，如改成tcp的话，通常端口相应修改成443 
proto udp
## 设置SSL/TLS根证书(ca)、证书(cert)和私钥(key)，记得我的服务器名是axvpn，这里也要相应修改 （必选） 
ca /home/dccmmtop/opt/openvpn_config/server/ca.crt 
cert /home/dccmmtop/opt/openvpn_config/server/yuanxin.crt 
key /home/dccmmtop/opt/openvpn_config/server/yuanxin.key 
## 指定迪菲·赫尔曼参数。 
## 默认是dh2048.pem, 记得我们生成了dh.pem，改下 （必选） 
dh /home/dccmmtop/opt/openvpn_config/server/dh.pem 




## 推送路由信息到客户端，以允许客户端能够连接到服务器背后的其他私有子网。 （可选） 
## 就是允许客户端访问VPN服务器自身所在的其他局域网 
server 30.8.0.0 255.255.0.0
ifconfig-pool-persist /home/dccmmtop/opt/openvpn_config/server/ipp.txt
## 通过keepalive检测超时后，重新启动vpn，不重新读取keys，保留第一次使用的keys
persist-key
## 通过keepalive检测超时后，重新启动vpn，一直保持tun或者tap设备是linkup的。否则链接会先linkdown 然后 linkup
persist-tun


## 客户端访问一下ip时，走vpn
push "route 40.18.14.0 255.255.255.0" 

## 使Client的默认网关指向VPN,让client的所有流量都走VPN
## push "redirect-gateway def1 bypass-dhcp"
##
## 允许多个客户端使用同一个证书链接服务器
duplicate-cn

## 控制最大客户端数量
## max-client 20


tls-auth /home/dccmmtop/opt/openvpn_config/server/ta.key 0
## 选择一个密码加密算法。 
## 该配置项也必须复制到每个客户端配置文件中。 
## 添加SHA256算法 
cipher AES-256-CBC 
user nobody 
group nobody 
## Notify the client that when the server restarts so it 
## can automatically reconnect. 
## 如果协议改成了TCP，这里数值要改成0 
##explicit-exit-notify 1 
##记录日志，每次重新启动openvpn后追加原有的log信息  6: DEBUG模式
verb 3
log-append /home/dccmmtop/log/openvpn.log
```

将服务端配置移动到 `$HOME/opt/openvpn_conf/server`

## 客户端配置
```conf
client
dev tun
tls-client
proto udp
## vpn server 地址 和端口
remote 10.100.200.69 1194
cipher AES-256-CBC
ca /home/dccmmtop/opt/openvpn_config/client/ca.crt
cert /home/dccmmtop/opt/openvpn_config/client/yuanxin_client.crt
key /home/dccmmtop/opt/openvpn_config/client/yuanxin_client.key
tls-auth /home/dccmmtop/opt/openvpn_config/client/ta.key 1

nobind
persist-key
persist-tun
remote-cert-tls server
verb 3
```
## 启动服务器
#### 开启 vpn server 端口
```shell
iptables -A INPUT -p tcp --dport 1194 -j ACCEPT
iptables -A INPUT -p udp --dport 1194 -j ACCEPT
```
#### 添加路由规则
```shell
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE 
```
#### 启动vpn server
```shell
$HOME/opt/openvpn/sbin/openvpn --config $HOME/opt/openvpn_config/server/server.conf
```

## VPN 其他知识
#### 邮局类比
想象一下，一家邮局不知道你的名字、姓氏或地址。邮局内部的邮局人员接收和发送的信件只包含关于您的一条信息——您的客户ID。邮局专门为您生成此ID，并对其保密。

当您收到一封信时，邮递员会使用此ID识别您，并将邮件直接转发给您。所有这些都是通过一个连接你的房子和办公室的超级秘密管道实现的。

同样，你也可以让这个快递员给世界上的任何人发封信。快递员会把你的信收起来，附上你的客户身份证，在上面盖上邮局地址，然后把它寄出去。就收件人而言，这封信是从邮局寄来的，不是你寄来的（除非你签了名）。

为了保护邮件内容和你的身份证，这些信件被翻译成只有你和邮递员才能理解的语言。所以即使有人收到你的邮件，他们也看不懂。
#### 可以做什么
###### 在线保护您的身份
不想留下数字面包屑，把你所有的在线活动都连接到你身上吗？使用VPN，您将隐藏您的IP地址（如您的家庭地址，但用于internet），向internet服务提供商屏蔽您的活动，等等！

###### 在公共Wi-Fi上保持安全

VPN使用加密来保护您的互联网活动免受窥探。它们与保护您的登录数据免受公共WiFi中间人攻击一样重要。当你享受旅行时，不要被黑客攻击！ 
 
[未完待续]

## HTTPS 与 VPN 的区别
HTTPS和VPN都会加密您的信息，但VPN会加密更多信息。HTTPS仅对通过浏览器发送到服务器和服务器的内容进行加密，并且仅在您访问的站点上启用了HTTPS。VPN将加密所有内容（正在进行的通信比你想象的要多得多！），只要你继续使用它

VPN通常使用更高级的加密方法。尽管任何加密都比不加密好，但VPN可以为您提供一流的安全性。它实现这一点的方法之一是使用处理大量数据的安全VPN协议，而加密只是其中的一部分

HTTPS可能容易受到某些类型的攻击。例如，HTTPS可能无法抵御根证书攻击，而您应该可以使用VPN。两者结合，就是完美的团队！

VPN不仅仅是加密数据。他们会改变你的IP地址，让你选择一个新的地理位置

|                VPS                |     HTTPS     |
| --------------------------------- | ------------- |
| 加密所有流量                       | 加密浏览器流量 |
| 使用更复杂的加密                   | 单一加密      |
| 抵御根证书攻击                     | 易受根证书攻击 |
| 更改您的IP，允许您选择新位置，等等！ | -             |
## 参考资料
- [openvpn官网](https://community.openvpn.net/openvpn/wiki/GettingStartedwithOVPN)
- https://bg6cq.github.io/ITTS/network/vpn/openvpn_ldap/
- http://home.ustc.edu.cn/~shaojiemike/posts/openvpn/##%E9%85%8D%E7%BD%AEopenvpn%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%AB%AF
- https://surfshark.com/learn/what-is-vpn
- https://surfshark.com/blog/vpn-vs-https