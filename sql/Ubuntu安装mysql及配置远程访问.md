---
title: Ubuntu 安装 mysql 及配置远程访问
tags: [mysql]
date: 2021-08-10 18:12:14
---

## 安装

```shell
sudo apt-get install mysql-server mysql-client
```

## 配置远程可连接

你想myuser使用mypassword（密码）从任何主机连接到mysql服务器的话。

```shell
　　mysql>GRANT ALL PRIVILEGES ON *.* TO '用户名'@'%'IDENTIFIED BY '你的密码' WITH GRANT OPTION;
```
如果你想允许用户myuser从ip为192.168.1.6的主机连接到mysql服务器，并使用mypassword作为密码
```shell
mysql>GRANT ALL PRIVILEGES ON *.* TO '用户名'@'192.168.1.3'IDENTIFIED BY '你的密码' WITH GRANT OPTION;
```
最后
```shell
mysql>FLUSH PRIVILEGES;
```
使修改生效，就可以了

## 在远程主机上开放防火墙端口

```shell
  sudo ufw allow 3306 
```
或者关闭防火墙（不推荐）`sudo ufw disable`

## 修改mysql配置文件

```shell
[mysqld]
    character-set-server = utf8
    bind-address = 0.0.0.0 //修改ip地址
    port = 3306
```
配置文件在/etc/mysql/mysql.conf.d/mysqld.cnf

重启mysql服务：`service mysql restart`

查看处于监听的服务状态：`sudo netstat -aptn`

## 阿里云主机

如果你要连接的远程主机是阿里云服务器还需要配置安全组规则！！！
开放入口，端口为3306/3306 优先级1 远程访问地址：0.0.0.0/0 点击保存