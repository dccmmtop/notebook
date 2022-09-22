---
title: bat脚本后台运行exe
date: 2022-09-22 14:32:14
tags: [win]
---

新建`start.bat`文件，输入如下命令：

```shell
@echo off 
if "%1" == "h" goto begin 
mshta vbscript:createobject("wscript.shell").run("%~nx0 h",0)(window.close)&&exit 
:begin

D:\123.exe
```
