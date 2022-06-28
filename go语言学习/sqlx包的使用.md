---
title: sqlx包的使用
date: 2021-11-16 22:07:23
tags: [go]
---

sqlx是一个第三方库，它为database/sql包提供了一系列非常有用的扩展功能。

因为sqlx和database/sql包使用的是相同的接口，所以sqlx能够很好地兼容使用database/sql包的程序， 除此之外，sqlx还提供了以下这些额外的功能：
- 通过结构标签（struct tag）将数据库记录（即行）封装为结构、映射或者切片；
- 为预处理语句提供具名参数支持。

## 表结构
```sql
create table blog
(
    id         int auto_increment
        primary key,
    title      varchar(255) not null,
    content    text         not null,
    creator_id int          not null
);
```
## 示例

```go
package main

import (
    "fmt"
    _ "github.com/go-sql-driver/mysql"
    "github.com/jmoiron/sqlx"
)

type Blog struct {
    Id        int
    Title     string
    Content string
    // 当属性与字段名不一致时，使用 struct_tag 进行映射
    Creator int `db:"creator_id"`
}

var db *sqlx.DB
func init(){
    var err error
    db, err = sqlx.Open("mysql","esns:dccmmtop@tcp(192.168.32.128:3306)/chitchat?parseTime=true")
    if err != nil {
        panic(err)
    }

}

func (blog *Blog)save(){
    result, err := db.Exec("insert into blog(title, content, creator_id) values (?,?,?)",blog.Title,blog.Content, blog.Creator)
    if err != nil {
        panic(err)
    }
    // mysql 不支持返回插入后的自增Id,需要额外处理
    id, err := result.LastInsertId()
    if err != nil {
        panic(err)
    }
    blog.Id =  int(id)
    return
}

func findById(id int)(blog Blog){
    blog = Blog{}
    // StructScan 会自动赋值属性
    err := db.QueryRowx("select id, title, content, creator_id from blog where id = ?", id).StructScan(&blog)
    if err != nil {
        panic(err)
    }
    return
}
func main(){
    blog := Blog{
        Title:     "go语言学习",
        Content:   "开启go编程之旅吧",
        Creator: 1,
    }
    blog.save()
    blog = findById(blog.Id)
    fmt.Printf("blog: %v\n", blog)
}
```