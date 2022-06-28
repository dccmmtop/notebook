---
title: Cookie操作
date: 2021-10-26 23:32:10
tags: [go]
---

## 将 cookie 发送给至客户端
Cookie结构的string方法可以返回一个经过序列化处理的cookie，其中Set-Cookie响应首部的值就是由这些序列化之后的cookie组成的。
```go
package main

import "net/http"

func main(){
    server := http.Server{
        Addr: "127.0.0.1:8080",
    }

    http.HandleFunc("/setCookie",setCookie)
    server.ListenAndServe()
}

func setCookie(w http.ResponseWriter, request *http.Request) {
    c1 := http.Cookie{
        Name: "first_cookie",
        Value: "吃饭了吗",
        HttpOnly: true,
    }
    c2 := http.Cookie{
        Name: "second_cookie",
        Value: "吃啥呢",
        HttpOnly: true,
    }
    // String() 方法返回序列化后得 cookie
    w.Header().Set("Cookie",c1.String())
    w.Header().Add("Cookie",c2.String())
    // 第二种设置 cookie 的方法
    c3 := http.Cookie{
        Name: "cookie3",
        Value: "天气怎么样",
        HttpOnly: true,
    }
    http.SetCookie(w, &c3)
}

```