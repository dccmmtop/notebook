---
title: nginx中location匹配规则
date: 2023-08-16 16:13:39
tags: [nginx]
---

精确匹配 / ，主机名后面不能带任何字符串
```conf
location = / {
    add_header Content-Type text/plain;
    return 200 'A';
}
```
或
```conf
location = /login {
    add_header Content-Type text/plain;
    return 200 'B';
}
```

匹配任何以 /static/ 开头的地址，匹配以后，不再继续往下检索正则，立即采用这一条。
```conf
location ^~ /static/ {
    add_header Content-Type text/plain;
    return 200 'C';
}
```

匹配所有以 txt 结尾的请求 然而，所有请求 /static/ 下的txt会被 规则 C 处理，因为 ^~ 到达不了这一条正则。
```conf
location ~* \.txt$ {
    add_header Content-Type text/plain;
    return 200 'F';
}
```

匹配任何以 /image/ 开头的地址，匹配符合以后，**还要继续往下搜索**, 注意与 ^~ /image/ 做区分
只有后面的正则表达式没有匹配到时，这一条才会采用这一条。
```conf
location /image {
    add_header Content-Type text/plain;
    return 200 'G';
}
```

因为所有的地址都以 / 开头，所以这条规则将匹配到所有请求。 但是正则和最长字符串会优先匹配。

```conf
location / {
    add_header Content-Type text/plain;
    return 200 'H';
}
```

> 联系方式: dccmmtop@foxmail.com