---
title: Go的模板引擎
date: 2021-11-01 22:51:35
tags: [go]
---
Go的模板都是文本文档（其中Web应用的模板通常都是HTML），它们都嵌入了一些称为动作（action）的指令。从模板引擎的角度来说，模板就是嵌入了动作的文本（这些文本通常包含在模板文件里面），而模板引擎则通过分析并执行这些文本来生成出另外一些文本。Go语言拥有通用模板引擎库 `text/template`，它可以处理任意格式的文本，除此之外，Go语言还拥有专门为HTML格式而设的模板引擎库 `html/template` 模板中的动作默认使用两个大括号 {{}}）包围，如果用户有需要，也可以通过模板引擎提供的方法自行指定其他定界符（delimiter）。

## 使用步骤
使用 Go 的模板引擎需要两个步骤：
1. 对文本格式的模板源进行语法分析，创建一个经过语法分析的模板结构，其中模板源既可以是一个字符串，也可以是模板文件包含的内容，
2. 执行经过语法分析的模板，将 ResponseWriter 和模板所需要的动态数据传递给模板引擎，被调用的模板引擎会把分析后的模板结构和数据结合起来，生成最终的HTML,并将HTML写入 ResponseWriter.
示例:
tmp.html:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
{{.}}
</body>
</html>
```

```go
package main

import (
    "html/template"
    "net/http"
)

func main(){
    server := http.Server{
        Addr: "127.0.0.1:8080",
    }
    http.HandleFunc("/process",process)
    server.ListenAndServe()

}

func process(w http.ResponseWriter, request *http.Request) {
    t, _ := template.ParseFiles("./tmpl.html")
    t.Execute(w, "你好哇！李银河")

    // 第二种方式
    /**
        t = template.New("tmpl.html")
        t.ParseFiles("./tmpl.html")
        t.Execute(w,"hello")
    */
}

```

## 对模板进行语法分析
ParseFiles是一个独立的（standalone）函数，它可以对模板文件进行语法分析，并创建出一个经过语法分析的模板结构以供Execute方法执行。实际上，ParseFiles函数只是为了方便地调用Template结构的ParseFiles方法而设置的一个函数-当用户调用Parseriles函数的时候，Go会创建一个新的模板，并将用户给定的**模板文件的名字用作这个新模板的名字**：
```go
t, _ := template.ParseFiles("tmpl.html")
```
这相当于创建一个新模板，然后调用它的ParseFiles方法
```go
t := template.New("tmpl.html")
t, _ := t.ParseFiles("tmpl.html")
```
上面两种方式都可以接受多个模板参数，**但只返回第一个参数对应的模板结构**
当用户向ParseFiles函数或Parseriles方法传入多个文件时，ParseFiles只会返回用户传入的第一个文件的已分析模板，并且这个模板也会根据用户传入的第一个文件的名字进行命名；至于其他传入文件的已分析模板则会被放置到一个映射里面，这个映射可以在之后执行模板时使用。
换句话说，我们可以这样认为：在向Parseriles传入单个文件时，Parseriles返回的是一个模板；而在向ParseFiles传入多个文件时，ParseFiles返回的则是一个模板集合，理解这一点能够帮助我们更好地学习嵌套模板技术。

### 对字符串分析
在绝大多数情况下，程序都是对模板文件进行语法分析，但是在需要时，程序也可以直接对字符串形式的模板进行语法分析。实际上，所有对模板进行语法分析的手段最终都需要调用Parse方法来执行实际的语法分析操作。比如说，在模板内容相同的情况下，语句
```go
t, _ := template.ParseFiles("./tmpl.html")
```
和代码
```go
tmpl := `<! DOCTYPE html>
<html><head>
<meta http-equiv="Content-Type"content="text/html; charset=utf-8">
<title>Go Web programming</title>
</head>
<body>
{.}}
</body></html>`
t := template. New ("tmpl. html")
t, = t. Parse (tmpl).
t. Execute (w, "Hello world!")
```
将产生相同的效果

### 对错误的处理
一直都没有处理分析模板时可能会产生的错误。虽然Go语言的一般做法是手动地处理错误，但Go也提供了另外一种机制，专门用于处理分析模板时出现的错误：
` t := template.Must(template.ParseFiles("tmpl.html"))`
Must函数可以包裹起一个函数，被包裹的函数会返回一个指向模板的指针和一个错误，如果这个错误不是nil，那么Must函数将产生一个panic。
> 在Go里面，panic会导致正常的执行流程被终止：如果panic是在函数内部产生的，那么函数会将这个panic返回给它的调用者。panic会一直向调用栈的上方传递，直至main函数为止，并且程序也会因此而崩溃。


## 执行模板
执行模板最常用的方法就是调用模板的Execute方法，并向它传递Responsewriter以及模板所需的数据。在只有一个模板的情况下，上面提到的这种方法总是可行的，但如果模板不止一个，那么当对模板集合调用Execute方法的时候，Execute方法只会执行模板集合中的第一个模板。如果想要执行的不是模板集合中的第一个模板而是其他模板，就需要使用ExecuteTemplate 方法
```go
t,_ := template.ParseFiles("t1. html", "t2. html")
```
变量t就是一个包含了两个模板的模板集合，其中第一个模板名为t1.html，而第二个模板则名为t2.html
（正如前面所说，除非显式地对模板名进行修改，否则模板的名字和后缀名将由传入的模板文件决定），如果对这个模板集合调用Execute方法：
```go
t.Execute(w,"你好哇！")
```
就只有模板t1.html会被执行。如果想要执行的是模板t2.html而不是t1.html，则需要执行以下语句：

```go
t.ExecuteTemplate(w,"t2.html","你好哇!")
``