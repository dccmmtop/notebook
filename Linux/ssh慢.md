---
title: ssh慢
date: 2021-08-10 10:48:44
---

在目标机器中修改/etc/ssh/sshd_conf文件
将UseDNS 的缺省值由yes修改为no，并重启ssh