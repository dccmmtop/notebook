---
title: jvm对象的内存分配与回收
date: 2022-08-28 22:27:11
tags: [java]
---

## 对象分配过程简略流程图
	
![](../images/Pasted%20image%2020220828231403.png)

## 对象栈上分配


我们都知道对象分配在堆上，当对象没有被引用时就会当成垃圾回收，如果对象数量比较多，会给GC带来较大的压力，影响性能，为了减少**临时对象**在堆内的分配次数，JVM 通过逃逸分析，确定该对象不会被外部访问。如果不会逃逸，可以将该对象在栈上分配。该对象所占用的空间就可以随着栈帧出栈而销毁，减轻了GC的压力

### 逃逸分析

```java
public User test1() {
   User user = new User();
   user.setId(1);
   user.setName("zhuge");
   //TODO 保存到数据库
   return user;
}

public void test2() {
   User user = new User();
   user.setId(1);
   user.setName("zhuge");
   //TODO 保存到数据库
}
```

test1 方法将 user 返回了，有可能被外部对象引用，其作用域范围不确定， test2 方法没有将 user  对象返回，其作用域仅仅在方法内部，没有逃出方法范围，可以把 user 进行栈内分配。


JVM 可以通过参数 -XX:DoEscapeAnalysis 开启逃逸分析，**JDK7 之后默认开启**


### 标量替换
将对象进行栈内分配时也不是将整个对象全部放到栈中，JVM 不会创建对象， 而是把对象拆开，将对象中的成员变量放到栈中，这样就不会因为没有一大块连续的空间导致对象内存不够分配

- 开启标量替换参数: -XX:+EliminateAllocations，JDK7之后默认开启。

如下面的例子:

```java
public class EscapeAnalysis {
    public Person p;
    /**
     * 发生逃逸，对象被返回到方法作用域以外，被方法外部，线程外部都可以访问
     */
    public void escape(){
        p = new Person(26, "TomCoding escape");
    }

    /**
     * 不会逃逸，对象在方法内部
     */
    public String noEscape(){
        Person person = new Person(26, "TomCoding noEscape");
        return person.name;
    }
}

static class Person {
    public int age;
    public String name;
    
    ... // 省略构造方法
}
```
比如上述noEscape()方法中person对象只会在方法内部，通过标量替换技术得到如下伪码：
```java
/**
 * 不会逃逸，对象在方法内部
 */
public String noEscape(){
    int age = 26;
    String name = "TomCoding noEscape";
    return name;
}
```

### 标量和聚合量

标量即不可被进一步分解的量，而JAVA的基本数据类型就是标量（如：int，long等基本数据类型以及reference类型等），标量的对立就是可以被进一步分解的量，而这种量称之为聚合量。而在JAVA中对象就是可以被进一步分解的聚合量 

### 栈上分配示例

```java
/**
 * 栈上分配，标量替换
 * 代码调用了1亿次alloc()，如果是分配到堆上，大概需要1GB以上堆空间，如果堆空间小于该值，必然会触发GC。
 * 
 * 使用如下参数不会发生GC
 * -Xmx15m -Xms15m -XX:+DoEscapeAnalysis -XX:+PrintGC -XX:+EliminateAllocations
 * 使用如下参数都会发生大量GC
 * -Xmx15m -Xms15m -XX:-DoEscapeAnalysis -XX:+PrintGC -XX:+EliminateAllocations
 * -Xmx15m -Xms15m -XX:+DoEscapeAnalysis -XX:+PrintGC -XX:-EliminateAllocations
 */
public class AllotOnStack {

    public static void main(String[] args) {
        long start = System.currentTimeMillis();
        for (int i = 0; i < 100000000; i++) {
            alloc();
        }
        long end = System.currentTimeMillis();
        System.out.println(end - start);
    }

    private static void alloc() {
        User user = new User();
        user.setId(1);
        user.setName("user1");
    }
}
```

可以根据打印的GC日志明显看出开启了栈内分配时，GC 次数远远小于不开启站内分配

## 在EDEN区分配

虽然jvm可以通过逃逸分析来将一部分对象进行栈上分配，但是在实际代码中，不逃逸的对象还是占少量的，大部分仍对象然分配在堆上的 EDEN 区

当Eden区没有足够的空间时将触发一次 Minor GC 

### 为什么 Eden 与 Survivor 的比例是 8:1:1
 大量对象被分配在 Eden 区，Eden 满了之后会触发Minor GC, 可能有99% 以上的对象被当作垃圾回收，剩余的存活对象被挪到为空的 survivor 区，下一次Eden满了之后，又会触发MinorGC ,把 Eden 和 Survivor 对象回收，把剩余的对象一次性挪到另一块为空的 Survivor 区。因为新生对象大部分寿命较短，所以 JVM 默认的比例 8:1:1 是非常合适的，让 Eden 足够大。 Survivor  够用即可。

JVM默认有这个参数-XX:+UseAdaptiveSizePolicy(默认开启)，会导致这个8:1:1比例**自动变化**，如果不想这个比例有变化可以设置参数-XX:-UseAdaptiveSizePolicy


#### 提前进入老年代

在发生MinorGC 后，Eden区的对象在向 Survivor 区转移时，如果 Survivor  区放不下这个对象。那么这个大对象直接进入老年代

相当于这个大对象跳过了 Survivor 区，直接进入空间更大的老年代区

#### 直接进入老年代的场景

在  Serial 和 ParNew 垃圾回收器下，大对象会直接进分配到老年代中，不经过 Eden 和 Survivor 区。 大对象就是需要连续大内存的对象,比如字符串，数组，这样做的好处是可以避免为大对象分配内存时的复制操作降低效率

可以通过参数调节大对象的阀值: -XX:PretenureSizeThreshold

例子: -XX:PretenureSizeThreshold=1000000 (单位是字节) -XX:+UseSerialGC

#### 长期存活的对象会进入老年代

如果对象在 Eden 出生并经过第一次 Minor GC 后仍然能够存活，并且能被 Survivor 容纳的话，将被移动到 Survivor   空间中，并将对象年龄设为1。对象在 Survivor 中每熬过一次 MinorGC，年龄就增加1岁，当它的年龄增加到一定程度 （默认为15岁，CMS收集器默认6岁，不同的垃圾收集器会略微有点不同），就会被晋升到老年代中。对象晋升到老年代的年龄阈值，可以通过参数 -XX:MaxTenuringThreshold 来设置。


#### 动态判断可能为长期对象

除了上述的对象年龄稳步增加到 15 后会移到老年代之外。还有一种动态计算年龄的方法:

当前放对象的Survivor区域里(其中一块区域，放对象的那块s区)，一批对象的总大小大于这块Survivor区域内存大小的50%(-XX:TargetSurvivorRatio可以指定)，那么此时大于等于这批对象年龄最大值的对象，就可以直接进入老年代了，例如Survivor区域里现在有一批对象，年龄1+年龄2+年龄n的多个年龄对象总和超过了Survivor区域的50%，此时就会把年龄n(含)以上的对象都放入老年代。这个规则其实是希望那些可能是长期存活的对象，尽早进入老年代。对象动态年龄判断机制一般是在minor gc之后触发的


## 垃圾回收器如何工作

### 引用计数法(差)

给对象中添加一个引用计数器，每当有一个地方引用它，计数器就加1；当引用失效，计数器就减1；任何时候计数器为0的对象就是不可能再被使用的。


**这种方法实现简单，效率高，当时目前主流的虚拟机并没有选择这种算法，主要他存在循环引用的问题:**

所谓对象之间的相互引用问题，除了对象objA 和 objB 相互引用着对方之外，这两个对象之间再无任何引用。但是他们因为互相引用对方，导致它们的引用计数器都不为0，于是引用计数算法无法通知 GC 回收器回收他们


### 可达性分析算法

将 **GC Roots** 对象作为起点，从这些节点开始向下搜索引用的对象，找到的对象都标记为非垃圾对象，其余未标记的对象都是垃圾对象

#### GC Roots
对象引用的根节点: 线程栈的本地变量、静态变量、本地方法栈的变量等等

![](../images/Pasted%20image%2020220830184513.png)

#### 常见的引用类型

java的引用类型一般分为四种：强引用、软引用、弱引用、虚引用

##### 强引用

普通的变量引用  

```java
 public static User user = new User();
```

##### 软引用

将对象用SoftReference软引用类型的对象包裹，正常情况不会被回收，但是GC做完后发现释放不出空间存放  
新的对象，则会把这些软引用的对象回收掉。软引用可用来实现内存敏感的高速缓存。  

```java
public static SoftReference<User> user =  new SoftReference<User>(new User());
```

软引用在实际中有重要的应用，例如浏览器的后退按钮。按后退时，这个后退时显示的网页内容是重新进行请求还是从  
缓存中取出呢？这就要看具体的实现策略了。  
（1）如果一个网页在浏览结束时就进行内容的回收，则按后退查看前面浏览过的页面时，需要重新构建  
（2）如果将浏览过的网页存储到内存中会造成内存的大量浪费，甚至会造成内存溢出  

#### 弱引用
将对象用WeakReference软引用类型的对象包裹，弱引用跟没引用差不多，GC会直接回收掉，很少用  
```java
public static WeakReference<User> user = new WeakReference<User>(new User());  
```

##### 虚引用

虚引用也称为幽灵引用或者幻影引用，它是最弱的一种引用关系，几乎不用



## 方法区的回收

方法区主要回收的是无用的类，那么如何判断一个类是无用的类的呢？  


类需要同时满足下面3个条件才能算是 “无用的类” ：  
- 该类所有的实例都已经被回收，也就是 Java 堆中不存在该类的任何实例。  
- 加载该类的 ClassLoader 已经被回收。  
- 该类对应的 java.lang.Class 对象没有在任何地方被引用，无法在任何地方通过反射访问该类的方法。