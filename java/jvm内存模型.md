---
title: jvm内存模型
date: 2022-08-22 07:58:28
tags: [java]
---

![](../images/Pasted%20image%2020220822080313.png)

## 线程共享
每个线程开启的时候都会划分几块内存空间，线程栈，程序计数器，本地方法栈。这几个内存空间是依附于线程的，线程结束后，这些空间也会释放

## 所有线程共享

除此之外还有堆，方法区，类加载子系统，字节码执行引擎。这些是所有线程共享的

## 本地方法栈

- 本地方法
简单地讲，**一个Native Method就是一个Java调用非Java代码的接囗**。该方法的实现由非Java语言实现，比如C。这个特征并非Java所特有，很多其它的编程语言都有这一机制，比如在C++中，你可以用extern "C" 告知C++编译器去调用一个C的函数。

在定义一个native method时，并不提供实现体（有些像定义一个Java interface），因为其实现体是由非java语言在外面实现的。

例如`java.lang.Object`中的`public final native Class<?> getClass()`方法；又如`java.lang.Thread`中的`private native void start0()`方法... ...

本地接口的作用是融合不同的编程语言为Java所用，它的初衷是融合C/C++程序。

- 本地方法栈
Java虚拟机栈于管理Java方法的调用，而**本地方法栈（Native Method Stack）用于管理本地方法的调用**。
本地方法栈，也是线程私有的。
## 程序计数器(PC)

在介绍jvm中的程序计数器(下面简称PC)之前，先看一下CPU 中的 PC:
- CPU 中的 PC 
我们用高级语言编写的复杂的程序最后都会转换成 CPU 可执行的指令，当程序运行的线程被中断的时候，需要用程序计数器记录当前执行到哪一条指令了，之后等待恢复的时候再从程序计数器中获取到被中断时执行的位置。也就是为 中断——恢复 提供一个记录

CPU中的PC是一个大小为一个字的存储设备（**寄存器**），在任何时候，PC中存储的都是内存地址（是不是有点像指针？），而CPU就根据PC中的内存地址，到相应的内存取出指令然后执行并且在更新PC的值。在计算机通电后这个过程会一直不断的反复进行。计算机的核心也在于此。

- JVM 中的 PC

在CPU中PC是一个物理设备，而java中PC则是一个一块比较小的**内存空间**，它是当前线程字节码执行的**行号指示器**。在java的概念模型中，字节码解释器就是通过改变这个计数器中的值来选取下一条执行的字节码指令的，它的程序控制流的指示器，分支，线程恢复等功能都依赖于这个计数器。

我们知道多线程的实现是多个线程轮流占用CPU而实现的，而在线程切换的时候就需要保存当前线程的执行状态，这样在这个线程重新占用CPU的时候才能恢复到之前的状态，而在JVM状态的保存是依赖于PC实现的，所以PC是线程所私有的内存区域，这个区域也是java运行时数据区域**唯一不会发生OOM的区域**

### jvm 指令概览
随便找一个class 文件， 执行下main命令可以解析 class 文件

```sell
javap -v App.class
```

输出:
```txt
Classfile /F:/code/java/io/dc/App.class
  Last modified 2022-8-19; size 1229 bytes
  MD5 checksum debb75f708cef09b6b1bf483b3e345ec
  Compiled from "App.java"
public class io.dc.App
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #18.#31        // java/lang/Object."<init>":()V
   #2 = Class              #32            // io/dc/App$MyClassLoader
   #3 = String             #33            // F:/code/java1
   #4 = Methodref          #2.#34         // io/dc/App$MyClassLoader."<init>":(Ljava/lang/String;)V
   #5 = String             #35            // io.dc.User
   #6 = Methodref          #2.#36         // io/dc/App$MyClassLoader.loadClass:(Ljava/lang/String;)Ljava/lang/Class;
   #7 = Methodref          #37.#38        // java/lang/Class.newInstance:()Ljava/lang/Object;
  .... 省略
public static void main(java.lang.String[]) throws java.lang.Exception;
descriptor: ([Ljava/lang/String;)V
flags: ACC_PUBLIC, ACC_STATIC
Code:
  stack=3, locals=9, args_size=1
	 0: new           #2                  // class io/dc/App$MyClassLoader
	 3: dup
	 4: ldc           #3                  // String F:/code/java1
	 6: invokespecial #4                  // Method io/dc/App$MyClassLoader."<init>":(Ljava/lang/String;)V
	 9: astore_1
	10: aload_1
	11: ldc           #5                  // String io.dc.User
	13: invokevirtual #6                  // Method io/dc/App$MyClassLoader.loadClass:(Ljava/lang/String;)Ljava/lang/Class;
	16: astore_2
	17: aload_2
	18: invokevirtual #7                  // Method java/lang/Class.newInstance:()Ljava/lang/Object;
	21: astore_3
	22: aload_2
	23: ldc           #8                  // String sout
```
其中 #1 #2 #3  就是程序计数器保存的内容，对应指令的位置
可以去官网找到每条指令的含义，示例如下:

![](../images/Pasted%20image%2020220822102447.png)


## 栈线程

栈具有先进后出的特性，线程栈内还有栈帧的概念，在一个线程中，每遇到一个方法都会开辟一个新的栈帧来存放方法相关的内容，栈帧内存放的还有局部变量表，操作数栈，动态链接，方法出口

栈线程的空间可以按需调整，有时我们会看到 StackOverflow 栈溢出错误，就是栈帧过多，空间不够用了，往往发生无限制的递归调用中。

### 局部变量表
顾名思义就是存放局部变量的一个表, 存放编译器生成的各种类型
- 基本类型（boolean,byte,char, short, float,long, double）
- 对象的引用
- try catch 中的异常
- 方法中的参数

局部变量表是以槽(shot)为单位的,其中**64位长度（long,double）类型数据占用俩个变量槽，而32位的占一个变量槽**。



用一个简单的demo 看一下槽的使用
```java
public class Main {
 public static void main(String[] args){
 int a=1;
 int b=2;
 System.out.println(a+b);
 }
}
```

反编译之后的jvm指令
```txt
public static void main(java.lang.String[]) throws java.io.IOException;
 descriptor: ([Ljava/lang/String;)V
 flags: ACC_PUBLIC, ACC_STATIC
 Code:
 stack=3, locals=3, args_size=1   //local就是局部变量表的大小
 0: iconst_1
 1: istore_1    //栈顶元素弹出存入变量表的槽1
 2: iconst_2
 3: istore_2    //栈顶元素弹出存入变量表的槽2
 4: getstatic     #2                  // Field java/lang/System.out:Ljava/io/PrintStream;
 7: iload_1
 8: iload_2
 9: iadd
 10: invokevirtual #3                  // Method java/io/PrintStream.println:(I)V
 13: return
 LineNumberTable:
 line 18: 0
 line 19: 2
 line 20: 4
 line 21: 13
 LocalVariableTable:
 Start  Length  Slot  Name   Signature
 0      14     0  args   [Ljava/lang/String;
 2      12     1     a   I
 4      10     2     b   I
 Exceptions:
 throws java.io.IOException
```

从上面的字节码文件中我们可以看出，在java源代码被编译成class文件后每一个方法的变量表的大小就已经确定（locals的值）。而且JVM是通过**索引**来操作变量表的，当使用的是32位数据类型时就索引N代表使用第N个变量槽。64位则代表第N和第N+1个变量槽，因为64为占用两个变量槽


### 操作数栈

Operand Stack，可以理解为存放操作数的栈。它的大小也是在编译期就已经确定好了的，就是上面反编译代码中出现的stack，栈元素可以是包括long和double在内的任意的java数据类型。

当一个方法刚开始执行的时候，操作数栈是空的，在方法执行的过程中字节码指令会往操作数栈内写入和取出元素。
```java
public static void main(java.lang.String[]) throws java.io.IOException;
 descriptor: ([Ljava/lang/String;)V
 flags: ACC_PUBLIC, ACC_STATIC
 Code:
 stack=3, locals=3, args_size=1  //栈深度最大为3，3个变量槽
 0: iconst_1             //常量1压入操作数栈 
 1: istore_1             //栈顶元素出栈存入变量槽1
 2: iconst_2             //常量2压入操作数栈
 3: istore_2             //栈顶元素出栈存入变量槽2
 4: getstatic     #2                  // Field java/lang/System.out:Ljava/io/PrintStream; 
 //调用静态方法main
 7: iload_1           //将变量槽1中值压入操作数栈
 8: iload_2           //将变量槽2中值压入操作数栈
 9: iadd              //从栈顶弹出俩个元素相加并且压入操作数栈
 10: invokevirtual #3                  // Method java/io/PrintStream.println:(I)V
 //调用虚方法
 13: return   //返回
```


### 动态链接
。。。 待续

### 方法出口

在方法调用结束后，必须返回到该方法最初被调用时的位置，程序才能继续运行，所以在栈帧中要保存一些信息，用来帮助恢复它的上层主调方法的执行状态。方法返回地址就可以是主调方法在调用该方法的指令的下一条指令的地址

## 堆

JVM中的堆是用来存放对象的内存空间，**几乎所有的Java对象、数组**都存储在JVM的堆内存中。比如当我们new一个对象或者创建一个数组的时候，就会在堆内存中分配出一段空间用来存放。类加载器读取了类文件后，需要把**类、方法、常变量**放到堆内存中，保存所有**引用类型**的真实信息，便于后续的执行。

物理上可以不是连续的，逻辑上是连续的

堆时JVM区域内存占用最大的一块，时垃圾回收的主要对象

### 堆内的划分
![](../images/Pasted%20image%2020220822151130.png)

- 新生代与老年代的默认比例  1:2
- 新生代区的默认比例是  8:1:1

在 HotSpot 中，Eden 空间和另外两个 SurvIvor 空间缺省所占的比例是 8:1:1
### 垃圾回收简述

随着程序的运行，Eden 区空间不足时会触发一次 Minor GC , 查找所有对 GC Root 的引用，包含间接引用。 每个对象都会被标记非垃圾，然后将非垃圾复制到 Survivor S0 中，同时给这些非垃圾对象打上一个经历Minor GC 的次数—— 代数，每经历一次 Minor GC ，就加1, 然后清空 Eden 区域，等下次 Eden 再次空间不足时，执行一次 GC,将 Eden 区 和 S0 区中的非垃圾复制到 S1 区， 对象的代数增加1，然后清空 Eden 和 S0 区。

S0 和 S1 这种左手换右手的方式不是无休止的，当代数增加到 15 ，就会把对象移到老年代，成为长期存在的对象。 除此之外，还有一种情况，即是当从Eden区复制内容到Survivor区时，复制内容大小超过S0或S1任一区域一半大小，也会直接被放入到老年代中，所以老年代才会需要那么大的区域

虽然老年代空间比较大，但终究也会有满的时候，当老年代的空间也满了,比较麻烦的事情就来了，会引发一次 full GC，在 full gc 时，jvm 会先触发 STW(Stop-The-World),暂停所有线程，回收整个内存模型中的内存资源，从而造成用户用户响应超时，或者系统无响应，对于并发高的系统影响极大。

通过gc机制，我们就可以得出一个简单有效的JVM优化办法，那就是减少full gc的次数，如何减少呢？只需要调整老年代和年轻代的内存空间分配使得在minor gc的过程中尽可能的消除大部分的垃圾对象。

比如这种`java -Xmx3072 -Xms3072M -Xmn2048M -Xss1M

**GC Roots**：在上面的gc过程中，我们还提到了JVM是如何判断垃圾对象的。简单地来说，就是从gc roots的根出发（即局部变量表中的引用对象），一路沿着引用关系找，凡是能够被找到的对象都是非垃圾对象，并且会被移动到下一个它应该去的区域中。剩下的对象，会在区域清空时，一同被清理掉而无须关心

### jvm 参数简单介绍

​ -Xmx3072M：设置JVM最大可用内存为3072M。  
​ -Xms3072M：设置JVM初始内存为3072M。此值可以设置与-Xmx相同，以避免每次垃圾回收完成后JVM重新分配内存。  
​ -Xmn2048M：设置年轻代大小为2G。增大年轻代后，将会减小年老代大小。不过此值对系统性能影响较大，Sun官方推荐配置为整个堆的3/8。  
​ -Xss1M：设置每个线程的堆栈大小。JDK5.0以后每个线程堆栈大小为1M，以前每个线程堆栈大小为256K。更具应用的线程所需内存大小进行调整。在相同物理内存下，减小这个值能生成更多的线程。

## 方法区

**方法区的基本理解：**
1.  方法区（Method Area) 与 Java 堆一样，是各个线程共享的内存区域。
2.  方法区在 JVM 启动的时候创建，并且它的实际的物理内存空间和 Java 堆区一样都可以是不连续的。
3.  方法区的大小，跟堆空间一样，可以选择固定大小或者可扩展。
4.  方法区的大小决定了**系统可以保存多少个类**，如果系统定义了太多的类，导致方法区的溢出，虚拟机同样会抛出内存溢出错误： java.lang.OutOfMemoryError:PermGen space 或者 java.lang.OutOfMemoryError:Metaspace
5.  关闭 JVM 就会释放这个内存区域。

**方法区内存设置**
- 元数据大小可以使用参数 -XX:MetaspaceSize 和 -XX:MaxMetaspaceSize 指定。
- 默认值依赖于平台。windows 下，-XX:MetaspaceSize 是 21M， -XX:MaxMetaspaceSize 的值是 -1，即没有限制。
- 与永久代不同，如果不指定大小，默认情况下，虚拟机会耗尽所有的可用系统内存。如果元数据发生异常，虚拟机一样会抛出异常 OutOfMemoryError:Metaspace
- -XX:MetaspaceSize 设置初始的元空间大小。对于一个 64 位的服务器 JVM 来说，其默认的 -XX:MetaspaceSize 值为21MB 。这就是初始的高水位线，一旦触及这个水位线， Full GC 将会被触发并卸载没用的类（即这些类对应的类加载器不再存活），然后这个高水位线将会重置。新的高水位线取决于 GC 释放了多少空间。如果释放的空间不足，那么在不超过 MaxMetaspaceSize时，适当提高该值。如果释放空间过多，则适当降低该值。
- 如果初始化的高水位线设置过低，上述高水位线调整情况会发生很多次。通过垃圾回收器的日志可以观察到 Full GC 多次调用。为了避免频繁的GC,建议将 -XX:MetaSpaceSize 设置为一个相对较高的值。

### 存储内容
它用于存储已被虚拟机加载的类信息、常量、静态变量、即时编译器编译后的代码缓存等。

#### 类型信息

对每个加载的类型（类 class、接口 interface、枚举enum、注解annotation），JVM 方法区中存储以下类型信息：

1.  这个类型的完整有效名称（全名=包名.类名）
2.  这个类型直接父类的完整有效名（对于 interface 或是 java.lang.Object，都没有父类）
3.  这个类型的修饰符（public,abstract ,final 的某个子集）
4.  这个类型直接接口的一个有序列表

#### 域（Field)信息

1.  JVM 必须在方法区中保存类型的所有域的相关信息以及域的声明顺序。
2.  域的相关信息包括：域名称、域类型、域修饰符（public,private,protected,static,final,volatile,transient 的某个子集)

#### 方法信息

JVM 必须保存所有方法的以下信息，同域信息一样包括声明顺序:

1.方法名称
2.方法的返回类型
3.方法参数的数量和类型（按顺序）
4.方法的修饰符（public ,private, protected , static ,final, synchronized, native,abstract 的一个子集）
5.方法的字节码（bytecodes)、操作数栈、局部变量表及大小（abstract 和 native方法除外）
6.异常表 （abstract 和 native 方法除外） 每个异常处理的开始位置、结束位置、代码处理在程序计数器中的偏移地址、被捕获的异常类的常量池索引
7.**non-final 的类变量** 静态变量和类关联在一起，随着类的加载而加载，他们成为类数据在逻辑上的一部分。
8.**全局常量：static final**, 被声明为 final 的类变量的处理方法则不同，每个全局常量在编译的时候就会被分配了。

###  运行时常量池 vs 常量池

-   方法区中，内部包含了运行时常量池
-   字节码文件，内部包含了常量池
  

### 为什么需要常量池

一个java源文件中类、接口、编译后产生一个字节码文件。而Java 中的字节码需要数据支持，通常这种数据会很大以至于不能直接存到字节码里，换另一种方式，可以存到常量池，这个字节码包含了指向常量池的引用。在动态链接的时候会用到运行时常量池，比如：如下的代码：

```java
public class SimpleClass{
    public void sayHello(){
        System.out.println("hello");
    }
}
```

虽然只有 194 字节，但是里面却使用了 String、 System、PrintStream及 Object 等结构。这里代码量其实已经很小了。如果代码多，应用到的结构会更多！这里就需要常量池了！

**小结**

常量池，可以看做是一张表，虚拟机指令根据这张常量表找到要执行的类名、方法名、参数类型、字面量等类型。

### 运行时常量池
- 运行时常量池（Runtime Constant Pool) 是方法区的一部分。
- 常量池表（Constant Pool Table) 是 **Class 文件的一部分**，用于存放编译期生成的各种字面量与符号应用，这部分内容将在类加载后存放到**方法区的运行时常量池中**
- 在加载类和接口到虚拟机后，就会创建对应的运行时常量池。
- JVM 为每个已加载到类型（类或接口）都维护了一个常量池。池中的数据项像数组项一样，是通过索引访问的。
- 运行时常量池中包含多种不同的常量，包括编译器就已经明确的数值字面量，也包括到运行期解析后才能够获得的方法或者字段引用。此时不再是常量池中的符号地址了，这里换为真实地址。
- 运行时常量池，相对于 Class 文件常量池的另一重要特征是：具备动态性。
- 运行时常量池类似于传统编程语言中的符号表（symbol table),但是它所包含的数据却比符号表要更加丰富一些。
- 当创建类或者接口的运行时常量池时，如果构造运行时常量池所需的内存空间超过了方法区所提供的最大值，则 JVM 会抛 OutOfMemoryError 异常。

### 方法区中的垃圾回收

方法区内常量池中主要存放的两大类常量：**字面量**和**符号引用**。字面量比较接近 Java语言层次的常量概念，如文本字符串、被声明为final的常量值等。而符号引用则属于**编译原理**方面的概念，包括下面三类常量：
1.类和接口的权限定名
2.字段的名称和描述符
3.方法的名称和描述符

HotSpot 虚拟机对常量池的回收策略是很明确的，之前常量池中的常量没有被任何地方引用，就可以回收。回收废弃常量与回收 java 堆中的对象非常类似。

判定一个常量是否“废弃”还是相对简单的，而要判定一个类型是否属于**不再被使用的类**的条件就比较苛刻了。需要同事满足下面三个条件：

1.  该类的所有实例都已经被回收了，也就是 java 堆中不存在该类及其任何派生子类的实例。
2.  加载该类的类加载器已经被回收，这个条件除非是经过精心设计的可替换类加载器的场景如 OSGI、JSP 的重加载等，否则通常是很难达成的。
3.  该类对应的 java.lang.Class 对象没有在任何地方被引用，无法在任何地方通过反射访问该类的方法。





















