---
title: 防止goroutine泄露的一般机制
date: 2022-02-21 19:23:11
tags: [go]
---
### goroutine 泄露
当 goroutine 被永远阻塞，或者只有主 goroutine 终止时，子 goroutine 才会终止，
即子goroutine 没有自行终止的时机
goroutine 便无法释放其所占的内存空间

### 一般解决方案:
由父goroutine告知子goroutine终止时机

准则: **父 goroutine 创建子 goroutine,那么父要确保子能够停止**

```go
package main

import (
	"fmt"
	"math/rand"
	"time"
)

func main() {
	done := make(chan interface{})
	randStream := newRandStream(done)
	fmt.Println("3 random ints:")
	for i := 1; i <= 3; i++ {
		fmt.Printf("%d: %d\n", i, <-randStream)
	}
	// 通知子goroutine停止
	close(done)

	// 模拟正在运行的工作
	time.Sleep(1 * time.Second)
}

// 生产者
// 只在生产者作用域内声明 chan, 并在内部进行写入逻辑，然后返回只读的通道, 防止在生产者外部向该通道中写入数据
// 维护了该通道的纯净
func newRandStream(done <-chan interface{}) <-chan int {
	randStream := make(chan int)
	go func() {
		// 当此goroutine结束时，打印。如果是main groutine 终止时，导致该goroutine终止，则不会打印
		defer fmt.Println("newRandStream closure existed")
		defer close(randStream)
		for {
			select {
			case randStream <- rand.Int():
			case <-done:
				// 接收到关闭信号,避免通道泄露
				return
			}
		}
	}()
	// 有一个隐式转换，将可读可写的 randStream 转换成只读的
	return randStream
}
```