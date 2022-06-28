---
title: select用法示例
date: 2022-02-21 19:06:18
tags: [go]
---

Go中的select和channel配合使用，通过select可以监听多个channel的I/O读写事件，当 IO操作发生时，触发相应的动作。

### 基本使用
```go
// 常规示例
func example() {
	done := make(chan interface{})
	// 一段时间后发送关闭信号
	go func() {
		time.Sleep(5 * time.Second)
		close(done)
	}()

	workCounter := 0
	breakLoop := false
	for {
		select {
		case <-done:
			breakLoop = true
		default:
		}
		if breakLoop {
			break
		}
		workCounter++
		time.Sleep(1 * time.Second)
	}
	fmt.Printf("收到结束信号，任务执行了 %d 次", workCounter)
}
```

### 超时机制
```go
package main
import (
    "fmt"
    "time"
)
func main() {
    ch := make(chan int)
    quit := make(chan bool)
    //新开一个协程
    go func() {
        for {
            select {
            case num := <-ch:
                fmt.Println("num = ", num)
            case <-time.After(3 * time.Second):
                fmt.Println("超时")
                quit <- true
            }
        }
    }()
    for i := 0; i < 5; i++ {
        ch <- i
        time.Sleep(time.Second)
    }
    // 收到超时信号，停止阻塞
    <-quit
    fmt.Println("程序结束")
}
```

### 最快返回
多个 goroutine 做同一件工作，取最快的返回结果

```go
package main
 
import (
    "fmt"
    "github.com/kirinlabs/HttpRequest"
)

func main() {
    ch1 := make(chan int)
    ch2 := make(chan int)
    ch3 := make(chan int)
    go Getdata("https://www.baidu.com",ch1)
    go Getdata("https://www.baidu.com",ch2)
    go Getdata("https://www.baidu.com",ch3)
    select{
        case v:=<- ch1:
            fmt.Println(v)
        case v:=<- ch2:
            fmt.Println(v)
        case v:=<- ch3:
            fmt.Println(v)
    }
}

func Getdata(url string,ch chan int){
    req,err := HttpRequest.Get(url)
    if err != nil{
    }else{
        ch <- req.StatusCode()
    }
}
```


### 死锁与默认情况
```go
package main

func main() {
    ch := make(chan string)
    select {
        case <-ch:
    }
}
```
在第 4 行创建了一个信道 ch。我们在 select 内部（第 6 行），试图读取信道 ch。由于没有 Go 协程向该信道写入数据，因此 select 语句会一直阻塞，导致死锁。该程序会触发运行时 panic

### 空select

```go
package main
func main() {
    select {}
}
```
除非有 case 执行，select 语句就会一直阻塞着。在这里，select 语句没有任何 case，因此它会一直阻塞，导致死锁。该程序会触发 panic