---
title: bat脚本后台运行exe
date: 2022-09-22 14:32:14
tags: [win]
---

新建`start.bat`文件，输入如下命令：

```bat
Set ws = CreateObject("Wscript.Shell") 
ws.run "cmd /c D:/1.exe",vbhide
```
