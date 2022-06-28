---
title: 利用cookie实现闪现消息
date: 2021-10-28 23:20:50
tags: [go]
---


为了向用户报告某个动作的执行情况，应用程序有时候会向用户展示一条简短的通知消息，
比如说，如果一个用户尝试在论坛上发表一篇帖子，但是这篇帖子因为某种原因而发表失败了，那么论坛应该向这个用户展示一条帖子发布失败的消息。
这种通知消息应该出现在用户当前所在的页面，但是在通常情况下，用户在访问这个页面时却不应该看到这样的消息。因此程序实际上要做的是在某个条件被满足时，才在页面上显示一条临时出现的消息，这样用户在刷新页面之后就不会再看见相同的消息了-我们把这种临时出现的消息称为闪现消息（flash message）

实现闪现消息的方法有很多种，但最常用的方法是把这些消息存储在页面刷新时就会被移除的会话cookie里面

## 添加闪现消息到cookie
setMessage处理器函数的定义跟之前展示过的setCookie处理器函数的定义非常相似，主要的区别在于setMessage对消息使用了Base64URL编码，以此来满足响应首部对cookie值的URL编码要求。在设置cookie时，如果cookie的值没有包含诸如空格或者百分号这样的特殊字符，那么不对它进行编码也是可以的；但是因为在发送闪现消息时，消息本身通常会包含诸如空格这样的字符，所以对cookie的值进行编码就成了一件必不可少的事情了。
```go
func setMessage(w http.ResponseWriter, r *http.Request) {
    msg := []byte("创建失败，缺少必填字段!")
    cookie := &http.Cookie{
        Name: "flash",
        // 必须对 cookie 进行url编码
        Value: base64.URLEncoding.EncodeToString(msg),
    }
    http.SetCookie(w, cookie)
}
```
## 展示闪现消息
```go
// 展示闪现消息
func showMessage(w http.ResponseWriter, r *http.Request) {
    msg, err := r.Cookie("flash")
    if err != nil {
        if err == http.ErrNoCookie {
            fmt.Fprintln(w, "not found message")
            return
        }
    }

    // 使cookie过期，让浏览器删除cookie
    cookie := http.Cookie{
        Name: "flash",
        MaxAge: -1,
        Expires: time.Unix(1,0),
    }
    http.SetCookie(w, &cookie)
    fmt.Fprintln(w, msg)
}
```

这个函数首先会尝试获取指定的cookie，如果没有找到该cookie，它就会把变量err设置成一个http.ErrNoCookie值，并向浏览器返回一条"No message found"消息。如果找到了这个cookie，那么它必须完成以下两个操作
1. 创建一个同名的cookie，将它的MaxAge值设置为负数，并且将Expires值也设置成一个已经过去的时间；
2. 使用SetCookie方法将刚刚创建的同名cookie发送至客户端。

初看上去，这两个操作的目的似乎是要替换已经存在的cookie，但实际上，因为新cookie的MaxAge值为负数，并且Expires值也是一个已经过去的时间，所以这样做实际上就是要完全地移除这个cookie。在设置完新cookie之后，程序会对存储在旧cookie中的消息进行解码，并通过响应返回这条消息。

## 完整代码
```go
package main

import (
    "encoding/base64"
    "fmt"
    "net/http"
    "time"
)

/**
 * 利用cookie实现闪现消息
 */
func main(){
    server := http.Server{
        Addr: "127.0.0.1:8080",
    }
    http.HandleFunc("setMessage",setMessage)
    http.HandleFunc("showMessage",showMessage)
    server.ListenAndServe()
}

// 展示闪现消息
func showMessage(w http.ResponseWriter, r *http.Request) {
    msg, err := r.Cookie("flash")
    if err != nil {
        if err == http.ErrNoCookie {
            fmt.Fprintln(w, "not found message")
            return
        }
    }

    // 使cookie过期，让浏览器删除cookie
    cookie := http.Cookie{
        Name: "flash",
        MaxAge: -1,
        Expires: time.Unix(1,0),
    }
    http.SetCookie(w, &cookie)
    fmt.Fprintln(w, msg)
}

func setMessage(w http.ResponseWriter, r *http.Request) {
    msg := []byte("创建失败，缺少必填字段!")
    cookie := &http.Cookie{
        Name: "flash",
        // 必须对 cookie 进行url编码
        Value: base64.URLEncoding.EncodeToString(msg),
    }
    http.SetCookie(w, cookie)
}
```