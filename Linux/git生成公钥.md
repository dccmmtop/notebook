---
title: git生成公钥
tags: [git]
date: 2021-08-10 17:50:06
---

Git配置多个SSH-Key 当有多个git账号时，比如：
a. 一个gitee，用于公司内部的工作开发；
b. 一个github，用于自己进行一些开发活动；

解决方法
生成一个公司用的SSH-Key
```shell
$ ssh-keygen -t rsa -C 'xxxxx@company.com' -f ~/.ssh/gitee_id_rsa
```
生成一个github用的SSH-Key
```shell
$ ssh-keygen -t rsa -C 'xxxxx@qq.com' -f ~/.ssh/github_id_rsa
```
在 ~/.ssh 目录下新建一个config文件，添加如下内容（其中Host和HostName填写git服务器的域名，IdentityFile指定私钥的路径）
```yml
# gitee
Host gitee.com
HostName gitee.com
PreferredAuthentications publickey
IdentityFile ~/.ssh/gitee_id_rsa
# github
Host github.com
HostName github.com
PreferredAuthentications publickey
IdentityFile ~/.ssh/github_id_rsa
```
用ssh命令分别测试
```shell
$ ssh -T git@gitee.com
$ ssh -T git@github.com
```