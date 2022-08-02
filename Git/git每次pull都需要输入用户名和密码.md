---
title: git每次pull都需要输入用户名和密码
tags: git
date: 2020-06-22 09:24:04
---

`git config --global credential.helper store`

这个时候~/.gitconfig文件中会多一行
```txt
[credential]
helper = store
```

2.执行git pull再次输入用户名和密码

此时你会看到/root/.git-credentials中会多一行内容。里面的内容类似https://{username}:{password}@github.com这种形式


