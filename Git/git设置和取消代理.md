---
title: git 设置和取消代理
tags: [git]
date: 2021-08-08 17:18:35
---
# 设置ss
```shell
git config --global http.proxy 'socks5://127.0.0.1:1080'

git config --global https.proxy 'socks5://127.0.0.1:1080'
```
# 设置代理
```shell
git config --global https.proxy http://127.0.0.1:1080

git config --global https.proxy https://127.0.0.1:1080
```
# 取消代理
```shell
git config --global --unset http.proxy

git config --global --unset https.proxy
```