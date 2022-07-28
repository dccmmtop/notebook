---
title:Linux下的循环
date:2022-07-28 18:26:36
tags: [linux]
---

## 数字性循环

```shell
#!/bin/bash
for((i=1;i<=10;i++));
do
echo $(expr $i \* 3 + 1);
done
```
```shell
#!/bin/bash
for i in $(seq 1 10)
do
echo $(expr $i \* 3 + 1);
done
```

```shell
#!/bin/bash
for i in {1..10}
do
echo $(expr $i \* 3 + 1);
done
```

```shell
#!/bin/bash
awk 'BEGIN{for(i=1; i<=10; i++) print i}'
```

## 字符性循环
```shell
#!/bin/bash
for i in `ls`;
do
echo $i is file name\! ;
done
```
```shell
#!/bin/bash
for i in $* ;
do
echo $i is input chart\! ;
done
```


```shell
#!/bin/bash
for i in f1 f2 f3 ;
do
echo $i is appoint ;
done
```

```shell
#!/bin/bash
list="rootfs usr data data2"
for i in $list;
do
echo $i is appoint ;
done
```
## 路径查找
```shell
#!/bin/bash

for file in /proc/*;
do
echo $file is file path \! ;
done
```

```shell
#!/bin/bash

for file in $(ls *.sh)
do
echo $file is file path \! ;
done
```


现在一般都使用for in结构，for in结构后面可以使用函数来构造范围，比如$()、``这些，里面写一些查找的语法，比如ls test*，那么遍历之后就是输出文件名了。
