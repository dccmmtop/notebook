---
title: ElasticSearch安装及配置
date: 2021-10-21 08:27:44
---

## 安装

## 配置
### 位置
解压tar.gz或ZIP压缩包后，可以在其config/目录中找到Elasticsearch的主要配置文件。
如果是通过RPM或DEB包安装的，文件在/etc/elasticsearch/中

### 集群名称
`cluster.name: elasticsearch-in-action`
默认情况下，新的节点通过多播发现已有的集群通过向所有主机发送ping请求，这些主机侦听某个特定的多播地址。如果发现新的集群而且有同样的集群名称，新的节点就会将加入他们。你需要定制化集群的名称，防止默认配置的实例加入到你的集群。为了修改集群名称，在elasticsearch.yml中解除cluster.name这一样的注释，并修改为你的集群名称
## 日志

如果需要查看Elastisearch的目志，默认的位置在解压zip或tar.gz包后的log/目录。如果是通过RPM或DEB包安装的，默认的路径是/var/log/elasticsearch/.

- 主要日志 
cluster-name.log
在这里将发现Elasticsearch运行时所发生一切的综合信息。例如，某个查询失败或一个新的节点加入集群
- 慢搜索日志
cluster-name_index_search_slowlog.log
当某个查询运行得很慢时 Elasticsearch在这里进行记录。默认情况下，如果一个查询花费的时间多于半秒，将在这里写人一条记录
- 慢索引日志(插入或更新慢)
cluster-name_index_indexing_slowlog.log
这和慢搜索日志类似，默认情况下，如果一个索引操作花费的时间多于半秒，将在这里写入一条记录

### 日志配置文件
logging.yml文件，它和elasticsearch.yml在同一个路径。
- rootLogger
和其他设置一样，日志的默认选项是合理的。但是，假设需要详细的日志记录，最佳的第一步是修改rootlogger，它将影响所有的日志。
现在我们还是使用默认值，但是如果想让Elasticsearch记录所有的事情，需要这样修改logging.yml的第一行：
```yml
rootLogger：TRACE,console,file
```
日志的默认级别是INFO

## JVM 配置
ES 是一个java程序，运行在JVM虚拟机中， JVM 和物理机相似，有自己的内存。JVM有其自己的配置，而其最为重要的一点是有多少内存可以使用。选择正确的内存设置对于Elasticsearch的性能和稳定性而言非常重要。

Elasticsearch使用的大部分内存称为“堆"（heap）。默认的设置让Elasticsearch为堆分配了256MB初始内存，然后最多扩展到1GBQ如果搜索和索引操作需要多于1GB的内存，那些操作将会失败，而且在日志中会发现超出内存（out-of-memory）错误,反之，如果在只有256MB 内存的设备上运行Elasticsearch，默认的设置可能就分配了太多的内存。

- ES_HEAP_SIZE
Linux
```shell 
export ES_HEAP_SIZE=500m; bin/elasticsearch
```
Windows
```bat
set ES_HEAP_SIZE=500m &  bin\elasticsearch.bat
```
有个一劳永逸的方法来设置堆的大小，就是修改bin/elasticearch.in.sh（Windows系统上是elasticsearch.bat）脚本。在文件的开始部分加入`ES_HEAP_SIZE=500m`
提示 如果是通过DEB包安装的Elasticsearch，则在/etc/defaultelasticsearch中修改这些变量。如果是通过RPM包安装的，则可以在/etc/sysconfig/elasticsearch配置同样的设置