---
title: Go逐行读取文件
date: 2022-07-28 09:03:18
tags: [go]
---

```go
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
)

func main() {

	filename := "./1.txt"
	f, err := os.Open(filename)
	if err != nil {
		fmt.Printf("璇诲彇 %s 澶辫触, err: %v\n", filename, err)
	}
	defer f.Close()
	reader := bufio.NewReader(f)

	for {
		line, _, err := reader.ReadLine()
		if err == io.EOF {
			fmt.Println("鍒拌揪鏂囦欢鏈熬锛宒one!")
			break
		}
		fmt.Println(line)
		// TODO
	}
}
```