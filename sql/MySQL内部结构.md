---
title: MySQL内部结构
date: 2022-08-01 22:20:58
tags: [MySQL]
---
大体来说，MySQL可以分为 server 层和存储引擎层两部分，如下图

![](../images/Pasted%20image%2020220801222250.png)


## Server层  
主要包括连接器、查询缓存、分析器、优化器、执行器等，涵盖 MySQL 的大多数核心服务功能，以及所有的内置函数   （如日期、时间、数学和加密函数等），所有**跨存储引擎**的功能都在这一层实现，比如存储过程、触发器、视图等。  
## Store层  
存储引擎层负责数据的存储和提取。其架构模式是插件式的，支持 InnoDB、MyISAM、Memory 等多个存储引擎。现在最常用的存储引擎是 InnoDB，它从 MySQL 5.5.5 版本开始成为了默认存储引擎。也就是说如果我们在create table时不指定表的存储引擎类型,默认会给你设置存储引擎为InnoDB。


## 连接器

顾名思义，他主要与客户端连接打交道

连接器负责跟客户端**建立连接、获取权限、维持和管理连接**。连接命令一般是这么写的：  

```sql
mysql ‐h host[数据库地址] ‐u root[用户] ‐p root[密码] ‐P 3306  
```
连接命令中的 mysql 是客户端工具，用来跟服务端建立连接。在完成经典的 TCP 握手后，连接器就要开始认证你的身份，  这个时候用的就是你输入的用户名和密码。  

1.如果用户名或密码不对，你就会收到一个"Access denied for user"的错误，然后客户端程序结束执行。  
2.如果用户名密码认证通过，连接器会到权限表里面查出你拥有的权限。之后，这个连接里面的权限判断逻辑，都将依赖于此时读到的权限。  

这就意味着，一个用户成功建立连接后，即使你用管理员账号对这个用户的权限做了修改，也不会影响已经存在连接的权限。修改完成后，只有再新建的连接才会使用新的权限设置。用户的权限表在系统表空间的mysql的user表中。

说到这里就有一个问题，为什么MySQL的权限不做成实时生效的呢？ 答案只有一个—— 为了性能

来看一下 MySQL 系统用户表:

```sql
select Host,User,Password from user;
```
![](../images/Pasted%20image%2020220801223648.png)

可以直接修改表中的数据来修改某个用户的权限

### 长连接和短连接

数据库里面，长连接是指连接成功后，如果客户端持续有请求，则一直使用同一个连接。

短连接则是指每次执行完很少的几次查询就断开连接，下次查询再重新建立一个。  

开发当中我们大多数时候用的都是长连接,把连接放在Pool内进行管理，但是长连接有些时候会导致 MySQL 占用内存涨得特别快，这是因为 MySQL 在执行过程中临时使用的内存是管理在连接对象里面的。这些资源会在连接断开的时候才释放。所以如果长连接累积下来，可能导致内存占用太大，被系统强行杀掉（OOM），从现象看就是 MySQL 异常重启了。  

**怎么解决这类问题呢**

1. 定期断开长连接。使用一段时间，或者程序里面判断执行过一个占用内存的大查询后，断开连接，之后要查询再重连。  
2. 如果你用的是 MySQL 5.7 或更新版本，可以在每次执行一个比较大的操作后，通过执行 mysql_reset_connection 来重新初始化连接资源。这个过程不需要重连和重新做权限验证，但是会将连接恢复到刚刚创建完时的状态。


## 查询缓存
参见[查询缓存](https://dccmmtop.github.io/posts/mysql%E4%B8%AD%E7%9A%84%E6%9F%A5%E8%AF%A2%E7%BC%93%E5%AD%98/)

## 分析器

如果没有命中查询缓存，就要开始真正的执行语句了，但是 MySQL 怎么知道你要查询的是哪张表格， 哪个字段，条件是什么呢？

这就是分析器大显身手的时候了，他会分析我们的 sql 语句，把你要查询的表，字段 和条件等都解析出来，形成特殊的结构，方便后续操作

如果 sql 语法不对，就会得到 "You have an error in your SQL syntax" 的错误提醒, 如下 from 错误的写成 form

```sql
mysql> select * fro test where id=1;  
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds t   o your MySQL server version for the right syntax to use near 'fro test where id=1' at line 1
```

但是分析器是如何解析sql语句的呢？ 底层是怎么工作的呢？

#### 词法分析器原理

词法分析器分成6个主要步骤完成对sql语句的分析  
1. 词法分析  
2. 语法分析  
3. 语义分析  
4. 构造执行树  
5. 生成执行计划  
6. 计划的执行

SQL语句的分析分为**词法分析与语法分析**，mysql的词法分析由MySQLLex[MySQL自己实现的]完成，语法分析由Bison生成。关于语法树大家如果想要深入研究可以参考[这篇wiki文章](https://en.wikipedia.org/wiki/LR_parser)

这里给出一个解析后的语法树，供参考

![](../images/Pasted%20image%2020220801231233.png)


## 优化器

经历过分析器后，MySQL 就知道自己需要做什么了， 但是程序员写出的 sql 语句可能不是最优的，这时，优化器可以对一些 sql 语句做出优化，不改变查询结果的前提下，使查询更高效

还可以决定某条 sql 使用那个索引查询更快。 或者会决定表关联的顺序 等等

有如下例子:

```sql
select * from test1 join test2 using(ID) where test1.name='张珊' and test2.name='莉丝';  
```

既可以先从表 test1 里面取出 name='张珊' ID 值，再根据 ID 值关联到表 test2，再判断 test2 里面 name的值是否等于 '莉丝'

也可以先从表 test2 里面取出 name='莉丝' 的记录的 ID 值，再根据 ID 值关联到 test1，再判断 test1 里面 name 的值是否等于 '张珊'

这两种执行方法的逻辑结果是一样的，但是执行的效率会有不同，而优化器的作用就是决定选择使用哪一个方案。优化器阶段完成后，这个语句的执行方案就确定下来了，然后进入执行器阶段

## 执行器

开始执行的时候，要先判断一下你对这个表 T 有没有执行查询的权限，如果没有，就会返回没有权限的错误，如下所示 (在 工程实现上，如果命中查询缓存，会在查询缓存返回结果的时候，做权限验证。查询也会在优化器之前调用 precheck 验证权 限)。  

要注意区分 连接器 中使用的权限， 连接器中的权限使用户级别的，而执行器中的权限使表级别的

```sql
select * from test where id=10;  
```
如果有权限，就打开表继续执行。打开表的时候，执行器就会根据表的引擎定义，去使用这个引擎提供的接口。  

比如我们这个例子中的表 test 中，ID 字段没有索引，那么执行器的执行流程是这样的：  
1. 调用 InnoDB 引擎接口取这个表的第一行，判断 ID 值是不是 10，如果不是则跳过，如果是则将这行存在结果集中；  
2. 调用引擎接口取“下一行”，重复相同的判断逻辑，直到取到这个表的最后一行。  
3. 执行器将上述遍历过程中所有满足条件的行组成的记录集作为结果集返回给客户端。  

至此，这个语句就执行完成了。对于有索引的表，执行的逻辑也差不多。第一次调用的是“取满足条件的第一行”这个接 口，之后循环取“满足条件的下一行”这个接口，这些接口都是引擎中已经定义好的。你会在数据库的慢查询日志中看到一个rows_examined 的字段，表示这个语句执行过程中扫描了多少行。这个值就是在执行器每次调用引擎获取数据行的时候累加的。在有些场景下，执行器调用一次，在引擎内部则扫描了多行，因此引擎扫描行数跟 rows_examined 并不是完全相同的


## bin_log 的使用

经常听到删库跑路的消息，其实删除库之后也不用跑路，MySQL 会把我们执行的每条SQL都记录到 bin-log中， 那么什么是 bin-log 呢？

binlog是Server层实现的二进制日志,他会记录我们的cud操作。Binlog有以下几个特点：

1. Binlog在MySQL的Server层实现（引擎共用）
2. Binlog为逻辑日志,记录的是一条语句的原始逻辑
3. Binlog不限大小,追加写入,不会覆盖以前的日志

 如果，我们误删了数据库,可以使用binlog进行归档!要使用binlog归档，首先我们得记录binlog，因此需要先开启MySQL的binlog功能。
 
### 配置my.cnf
```cnf
log-bin=/usr/local/mysql/data/binlog/mysql-bin 

# 注意5.7以及更高版本需要配置本项：（自定义,保证唯一性)
# server-id=123454
#binlog格式，有3种statement,row,mixed 
binlog-format=ROW 

#表示每1次执行写入就与硬盘同步，会影响性能，为0时表示，事务提交时mysql不做刷盘操作，由系统决定
sync-binlog=1
```

### binlog命令

查看bin-log是否开启

```shell
 show variables like '%log_bin%';
```
 
会多一个最新的bin-log日志
```shell
 flush logs;
```

 查看最后一个bin-log日志的相关信息
```shell
show master status;
```

 清空所有的bin-log日志
```shell
reset master;
```

查看binlog内容

```shell
/usr/local/mysql/bin/mysqlbinlog --no-defaults /usr/local/mysql/data/binlog/mysql-bin.000001
```

### 数据恢复

#### 恢复全部数据
```shell
/usr/local/mysql/bin/mysqlbinlog --no-defaults /usr/local/mysql/data/binlog/mysql-bin.000001 |mysql -uroot -p test # test 是数据库名
```
#### 恢复指定时间段数据

```shell
/usr/local/mysql/bin/mysqlbinlog --no-defaults /usr/local/mysql/data/binlog/mysql-bin.000001 --stop-date= "2018-03-02 12:00:00"  --start-date= "2019-03-02 11:55:00"|mysql -uroot -p test
```

### 恢复指定位置数据

```shell
/usr/local/mysql/bin/mysqlbinlog --no-defaults --start-position="408" --stop-position="731"  /usr/local/mysql/data/binlog/mysql-bin.000001 |mysql -uroot -p test
```

--start-position  = "408" --start-position  = ''731"

怎么找到呢？

我们需要使用工具查看bin-log信息:

```shell
/usr/local/mysql/bin/mysqlbinlog --no-defaults /usr/local/mysql/data/binlog/mysql-bin.000001 --stop-date= "2018-03-02 12:00:00"  --start-date= "2019-03-02 11:55:00"|mysql -uroot -p test
```
信息如下:
![](../images/Pasted%20image%2020220802112217.png)

由此便可以恢复指定位置或日期的数据了.