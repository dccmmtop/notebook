---
title: "map"
date: "2021-07-29 23:41:36"
---

### map 支持的操作

1. 删除key
`delete(mapName, keyName)`
2. 获取键值对数量
`len(mapName)`


## 注意
1. 并发不安全
2. 不能直接修改map中的值 x = y , x 必须是可以寻址的，才能把y赋值给x
  map 扩容时，value 的地址会变化，不可以寻址(没有固定值),所以不可以赋值
  如下
```go
package main
import "fmt"

func main(){
  type User struct{
    Name string
    Age int
    Sex rune
  }

  users := make(map[int]User)
  user := User{
    Name: "zhangsan",
    Age: 10,
    Sex: 'w',
  }

  users[1] = user
  // users[1].Age = 11 // 错误,不能通过users引用直接修改
  /**
  x = y , x 必须是可以寻址的，才能把y赋值给x
  map 扩容时，value 的地址会变化，不可以寻址(没有固定值),所以不可以赋值
  */

  user.Age = 12
  users[1] = user // 必须整体替换value

  fmt.Printf("users: %v\n",users)

}

```