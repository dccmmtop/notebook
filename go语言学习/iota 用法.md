---
title: "iota 用法"
date: "2021-07-29 22:49:53"
---

用在常量声明中，初始值为0，一组常量同时声明时，其值逐行增加

### 类似枚举
```go
const (
  c0 = iota //c0 == 0
  c1 = iota //c1 == 1
  c2 = iota //c2 == 2
)
```
简写模式
```go
const (
  c0 = iota // c0 == 0
  c1        // c1 == 1
  c2        // c2 == 2
)
```

### 分开的const
分开的const语句， iota 的值每次都是从0开始

`const c0 = iota // c0 == 0`
`const c1 = iota // c1 == 0`