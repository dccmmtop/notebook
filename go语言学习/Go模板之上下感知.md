---
title: Go模板之上下文感知
date: 2021-11-08 21:32:35
tags: [go]
---
## 上下文感知
Go语言的模板引擎可以根据内容所处的上下文改变其显示.
上下文感知的一个显而易见的用途就是对被显示的内容实施正确的转义（escape）：这意味着，如果模板显示的是HTML格式的内容，那么模板将对其实施HTML转义；如果模板显示的是JavaScript格式的内容，那么模板将对其实施JavaScript转义；诸如此类。除此之外，Go模板引擎还可以识别出内容中的URL或者css样式。

## 示例
```go
package main

import (
    "html/template"
    "net/http"
)

func main()  {
    server := http.Server{
        Addr: "127.0.0.1:8080",
    }
    http.HandleFunc("/testContextAware", testContextAware)
    server.ListenAndServe()
}

func testContextAware(w http.ResponseWriter, r *http.Request) {
    t, err := template.ParseFiles("./testContextAware.tmpl")
    if err != nil {
        panic(err)
    }
    content := `我问: <i> "发生了什么" </i>`
    err = t.Execute(w,content)
    if err != nil {
        panic(err)
    }
}
```
- 上下文感知模板
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
<div>{{ . }}</div>
<div><a href="/{{ . }}">Path</a></div>
<div><a href="/?q={{ . }}">Query</a></div>
<div><a onclick="f ('{{ .}}') ">Onclick</a></div>
</body>
</html>
``
## 结果
```txt
HTTP/1.1 200 OK
Date: Mon, 08 Nov 2021 13:52:59 GMT
Content-Length: 569
Content-Type: text/html; charset=utf-8

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
<div>我问: &lt;i&gt; &#34;发生了什么&#34; &lt;/i&gt;</div>
<div><a href="/%e6%88%91%e9%97%ae:%20%3ci%3e%20%22%e5%8f%91%e7%94%9f%e4%ba%86%e4%bb%80%e4%b9%88%22%20%3c/i%3e">Path</a></div>
<div><a href="/?q=%e6%88%91%e9%97%ae%3a%20%3ci%3e%20%22%e5%8f%91%e7%94%9f%e4%ba%86%e4%bb%80%e4%b9%88%22%20%3c%2fi%3e">Query</a></div>
<div><a onclick="f ('我问: \u003ci\u003e \u0022发生了什么\u0022 \u003c\/i\u003e') ">Onclick</a></div>
</body>
</html>
```

原本有可能会被浏览器执行的js已经被转义了，原样展示

## 应用场景
由上可见，上下文感知特性可以很方便的避免XSS攻击
上下文感知功能不仅能够自动对HTML进行转义，它还能够防止基于JavaScript，Css甚至URL的XSS攻击。那么这是否意味着我们只要使用Go的模板引擎就可以无忧无虑地进行开发了呢？并非如此，上下文感知虽然很方便，但它并非灵丹妙药，而且有不少方法可以绕开上下文感知。

实际上，如果需要，用可以完全不使用上下文感知特性的。

## 不使用上下文感知

可以使用类型转换，把内容转换成html
```go
func testContextAware(w http.ResponseWriter, r *http.Request) {
    t, err := template.ParseFiles("./testContextAware.tmpl")
    if err != nil {
        panic(err)
    }
    content := `我问: <i> "发生了什么" </i>`
    err = t.Execute(w,template.HTML(content))
    if err != nil {
        panic(err)
    }
}
```