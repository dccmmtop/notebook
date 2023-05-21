---
title: centos防火墙
date: 2023-05-20 16:02:13
tags: [linux]
---


在 CentOS 操作系统中，Firewall 和 iptables 都可以用于网络安全。

Firewall 在 **CentOS 7 及其之后**版本中已成为默认的防火墙解决方案。它基于 Netfilter 框架，并使用 firewalld 作为前端管理工具。Firewall 可以通过命令行工具 firewall-cmd 进行配置和管理，也可以使用图形界面工具 firewall-config 进行操作。Firewall 具有易用性和灵活性，可以通过 zone 的方式对不同的网络环境进行不同的安全策略设置。

而在** CentOS 6 及其之前版本中**，iptables 是默认的防火墙解决方案。它基于 Netfilter 框架，可以通过命令行工具 iptables 进行配置和管理。iptables 的配置需要比较丰富的网络知识，操作比较复杂，但可以实现更细粒度的安全策略设置。

需要注意的是，Firewall 和 iptables 在 CentOS 中是**互不兼容的**。如果启用了 Firewall，则 iptables 将被禁用。如果需要使用 iptables，需要先停止并禁用 Firewall 服务

## firewalld

### 启动
```shell
systemctl start firewalld
```
### 停止服务
```shell
systemctl stop firewalld
```
### 禁用服务
```shell
systemctl mask firewalld
```
### 查看状态
```shell
firewall-cmd --state
```

### 添加规则
```shell
firewall-cmd --add-port=11011/tcp --permanent
firewall-cmd --reload
```

### 清空所有规则
```shell
firewall-cmd --permanent --list-all | grep ports | head -n 1 |  cut -d: -f2 | tr ' ' '\n' | xargs -I {} firewall-cmd --permanent --remove-port={}
```

### 查看现有规则
```shell
firewall-cmd --list-all
```

## 端口状态
```shell
yum install net-tools -y
```

```shell
netstat -nlp //查看所有端口的监听情况
netstat -nlp |grep 80 //查看某个端口的监听情况
ps -ef | grep httpd //查看某个服务的运行状况
```



## iptable-service

安装iptable iptable-service


### 检查是否安装了iptables
` service iptables status `

### 安装iptables

`yum install -y iptables`

### 升级iptables

`yum update iptables `

### 安装iptables-services

`yum install iptables-services`

### 开启服务
`systemctl start iptables.service`
### 查看状态
`systemctl status iptables.service`

### 查看iptables现有规则
`iptables -L -n`
### 先允许所有,不然有可能会杯具
`iptables -P INPUT ACCEPT`
### 清空所有默认规则
`iptables -F`
### 清空所有自定义规则
`iptables -X`
### 所有计数器归0
`iptables -Z`
### 允许来自于lo接口的数据包(本地访问)
`iptables -A INPUT -i lo -j ACCEPT`
### 开放22端口
`iptables -A INPUT -p tcp --dport 22 -j ACCEPT`
### 开放21端口(FTP)
`iptables -A INPUT -p tcp --dport 21 -j ACCEPT`
### 开放80端口(HTTP)
`iptables -A INPUT -p tcp --dport 80 -j ACCEPT`
### 开放443端口(HTTPS)
`iptables -A INPUT -p tcp --dport 443 -j ACCEPT`
### 允许ping
`iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT`
### 允许接受本机请求之后的返回数据 RELATED,是为FTP设置的
`iptables -A INPUT -m state --state  RELATED,ESTABLISHED -j ACCEPT`
### 其他入站一律丢弃
`iptables -P INPUT DROP`
### 所有出站一律绿灯
`iptables -P OUTPUT ACCEPT`
### 所有转发一律丢弃
`iptables -P FORWARD DROP`

其他规则设定

### 如果要添加内网ip信任（接受其所有TCP请求）
`iptables -A INPUT -p tcp -s 45.96.174.68 -j ACCEPT`
### 过滤所有非以上规则的请求
`iptables -P INPUT DROP`
### 要封停一个IP，使用下面这条命令：
`iptables -I INPUT -s ***.***.***.*** -j DROP`
### 要解封一个IP，使用下面这条命令:
`iptables -D INPUT -s ***.***.***.*** -j DROP`
### 保存上述规则
`service iptables save`
### 相当于以前的chkconfig iptables on
`systemctl enable iptables.service`