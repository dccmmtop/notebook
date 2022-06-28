---
title: gorm包使用
date: 2021-11-16 23:14:23
tags: [go]
---

## 自动迁移
因为Gorm可以通过自动数据迁移特性来创建所需的数据库表，并在用户修改相应的结构时自动对数据库表进行更新， 当我们运行这个程序时，程序所需的数据库表就会自动生成

负责执行数据迁移操作的AutoMigrate方法是一个变长参数方法，这种类型的方法和函数能够接受一个或多个参数作为输入。

在下面展示的代码中，AutoMigrate方法接受的是Post结构和Comment结构。得益于自动数据迁移特性的存在，当用户向结构里面添加新字段的时候，Gorm就会自动在数据库表里面添加相应的新列。

## 自动设置创建时间

Comment结构里面出现了一个类型为time.Time的CreatedAt字段，包含这样一个字段意味着Gorm每次在数据库里创建一条新记录的时候，都会自动对这个字段进行设置。
此外，Comment结构的其中一些字段还用到了结构标签，以此来指示Gorm应该如何创建和映射相应的字段。比如，Comment结构的Author字段就使用了结构标签、sql："not null"，以此来告知Gorm，该字段对应列的值不能为null

## 处理映射关系
在Comment结构里设置了一个PostId字段。Gorm会自动把这种格式的字段看作是外键，并创建所需的关系。

## 示例代码
```go
package main
import (
  "fmt"
  _ "github.com/go-sql-driver/mysql"
  "github.com/jinzhu/gorm"
  "time"
)

type Post struct {
  // 会被自动设置成主键
  Id int
  Content string
  // 数据库层面不可以为空约束
  Author string `sql:"not null"`
  Comments []Comment
  // 约定。 创建时会被自动赋值
  CreatedAt time.Time
}

type Comment struct {
  Id int
  Content string
  Author string `sql:"not null"`
  // 以Id结尾的字段被视为外键,在关联对象时起作用.  index 会在此字段上创建索引
  PostId int `sql:"index"`
  CreatedAt time.Time
}

var Db *gorm.DB
func init(){
  var err error
  Db, err = gorm.Open("mysql","esns:dccmmtop@tcp(192.168.32.128:3306)/chitchat?parseTime=true")
  if err != nil {
    panic(err)
  }
  // 开启详细日志，会把执行的sql打印出来
  Db.LogMode(true)
  // 执行数据库迁移。包括新增表，新增字段，修改字段
  Db.AutoMigrate(&Post{},&Comment{})
}



func main() {
  post := Post{
    Content: "乱花渐欲迷人眼",
    Author: "李商隐",
  }
  // 创建post,并映射
  Db.Create(&post)
  comment := Comment{
    Content:   "太棒了",
    Author:    "李白",
  }
  // 创建关联的对象。这里通过外键Id 自动查找映射关系
  Db.Model(&post).Association("Comments").Append(comment)
  var readPost Post
  // 查询
  Db.Where("id =  ?", post.Id).First(&readPost)
  var comments []Comment
  // 关联查询
  Db.Model(&readPost).Related(&comments)
  fmt.Printf("post: %v\n",readPost)
  fmt.Printf("comments: %v\n",comments)
}

```

gorm 官方文档有详细的教程 [https://gorm.io/zh_CN/](https://gorm.io/zh_CN/)
