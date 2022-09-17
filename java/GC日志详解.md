---
title: GC日志详解
date: 2022-09-17 09:58:27
tags: [java]
---

对于 java 应用我们可以通过一些配置把程序运行过程中的 gc 日志全部打印出来，然后分析 gc 日志得到关键性指标，分析 GC 原因，调优 JVM 参数：


## 开启 GC 日志相关参数
```shell
java -jar 
‐Xloggc:./gc‐%t.log 
‐XX:+PrintGCDetails 
‐XX:+PrintGCDateStamps 
‐XX:+PrintGCTimeStamps 
‐XX:+PrintGCCause   
‐XX:+UseGCLogFileRotation 
‐XX:NumberOfGCLogFiles=10 
‐XX:GCLogFileSize=100M
main.jar
```

- gc-%t.log 日志文件带时间 
- +PrintGCDetails  打印详细信息
- +PrintGCDateStamps 打印日期
- +PrintGCTimeStamps  打印时间 
- +PrintGCCause 打印 GC 原因
- +UseGCLogFileRotation 开启日志轮换
- NumberOfGCLogFiles GC 日志保留个数
- GCLogFileSize 每个日志文件的大小


## 查看jvm所有参数
- java -XX:+PrintFlagsInitial 表示打印出所有参数选项的默认值  
- java -XX:+PrintFlagsFinal 表示打印出所有参数选项在运行程序时生效的值



## GC 日志分析
![](../images/Pasted%20image%2020220917100539.png)

我们可以看到图中第一行红框，是项目的配置参数。这里不仅配置了打印 GC 日志，还有相关的 VM 内存参数。  
第二行红框中的是在这个 GC 时间点发生 GC 之后相关 GC 情况。  
1. 对于 2.909： 这是从 jvm 启动开始计算到这次 GC 经过的时间，前面还有具体的发生时间日期。  
2. Full GC(Metadata GC Threshold)指这是一次 full gc，括号里是 gc 的原因， PSYoungGen 是年轻代的 GC， ParOldGen 是老年代的 GC，Metaspace 是元空间的 GC  
3. 6160K->0K(141824K)，这三个数字分别对应 GC 之前占用年轻代的大小，GC 之后年轻代占用，以及整个年轻代的大小。  
4. 112K->6056K(95744K)，这三个数字分别对应 GC 之前占用老年代的大小，GC 之后老年代占用，以及整个老年代的大小。  
5. 6272K->6056K(237568K)，这三个数字分别对应 GC 之前占用堆内存的大小，GC 之后堆内存占用，以及整个堆内存的大小。  
6. 20516K->20516K(1069056K)，这三个数字分别对应 GC 之前占用元空间内存的大小，GC 之后元空间内存占用，以及整个元空间内存的大小。  
7. 0.0209707 是该时间点 GC 总耗费时间

从日志可以发现几次fullgc都是由于元空间不够导致的，所以我们可以将元空间调大点：

```txt
‐XX:MetaspaceSize=256M ‐XX:MaxMetaspaceSize=256M
```

## GC日日志分析工具
GC 日志太多，人工无法很好的分析出原因，可以利用一些工具：
- gceasy https://gceasy.io/
以图形的方式展现内存变化等，还会给出一些 jvm 参数优化的建议，目前这个功能应该收费了

## GC日志对性能的影响

其实GC日志就是 jvm 执行期间那些 C++ 代码打印的日志而已，和我们应用中的日志没有差别，只要系统没有非常频繁的发生GC 会导致日志太大，对应用造成的性能影响可以忽略
