---
title: Go读写CSV
date: 2021-11-09 22:47:15
tags: [go]
---

对Go语言来说，CSV文件可以通过encoding/csv包进行操作，下面通过这个包来读写CSV文件。

由于程序在接下来的代码中立即就要对写入的posts.csv文件进行读取，而刚刚写入的数据有可能还滞留在缓冲区中，所以程序必须调用写入器的Flush方法来保证缓冲区中的所有数据都已经被正确地写入文件里面了。


读取CSV文件的方法和写人文件的方法类似。首先，程序会打开文件，并通过将文件传递给NewReader函数来创建出一个读取器（reader），接着，程序会将读取器的FieldsPer Record字段的值设置为负数，这样的话，即使读取器在读取时发现记录（record）里面缺少了某些字段，读取进程也不会被中断。

反之，如果FieldsPerRecord字段的值为正数，那么这个值就是用户要求从每条记录里面读取出的字段数量，当读取器从CsV文件里面读取出的字段数量少于这个值时，Go就会抛出一个错误。

最后，**如果FieldsPerRecord字段的值为0，那么读取器就会将读取到的第一条记录的字段数量用作FieldsPerRecord的值。**


在设置好FieldsPerRecord字段之后，程序会调用读取器的ReadAl1方法，一次性地读取文件中包含的所有记录；但如果文件的体积较大，用户也可以通过读取器提供的其他方法，以每次一条记录的方式读取文件。

```go
package main

import (
    "encoding/csv"
    "fmt"
    "os"
    "strconv"
)

type Blog struct {
    Id int
    Content string
}

func main(){
    csvFile, err := os.Create("testCsv.csv")
    if err != nil {
        panic(err)
    }
    defer csvFile.Close()
    csvWriter := csv.NewWriter(csvFile)

    allPost := []Blog{
        {Id: 1, Content: "昨夜西风凋敝树"},
        {Id: 2, Content: "忽如一夜春风来"},
        {Id: 3, Content: "千树万树梨花开"},
        {Id: 4, Content: "卷我屋上三重茅"},
    }

    for _, blog := range allPost {
        csvWriter.Write([]string{strconv.Itoa(blog.Id), blog.Content})
    }
    csvWriter.Flush()

    // 读取csv
    file,err  := os.Open("./testCsv.csv")
    if err != nil {
        panic(nil)
    }
    defer file.Close()

    csvReader := csv.NewReader(file)
    // 设置每行至少的列数,遇到少于此数的行数会报错。-1 代表不检查列数
    csvReader.FieldsPerRecord = -1
    record, err := csvReader.ReadAll()
    if err != nil {
        panic(err)
    }

    var posts []Blog
    for _, item := range record {
        id ,_ := strconv.ParseInt(item[0],0,0)
        post := Blog{Id: int(id), Content: item[1]}
        posts = append(posts,post)
    }
    fmt.Println(posts[0])
}

```