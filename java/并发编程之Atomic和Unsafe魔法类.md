---
title: 并发编程之Atomic和Unsafe魔法类
date: 2022-10-11 11:03:04
tags: [java]
---

## 原子操作
原子（atom）本意是“不能被进一步分割的最小粒子”，而原子操作（atomic operation）意为”不可被中断的一个或一系列操作” 。在多处理器上实现原子操作就变得有点复杂 

### 处理器会保证基本内存操作的原子性
处理器保证从系统内存当中读取或者写入一个字节是原子的，意思是**当一个处理器读取一个字节时，其他处理器不能访问这个字节的内存地址**。奔腾 6 和最新的处理器能自动保证单处理器对同一个缓存行里进行 16/32/64 位的操作是原子的，但是**复杂的内存操作处理器不能自动保证其原子性**，比如跨总线宽度，跨多个缓存行，跨页表的访问。但是处理器提供**总线锁定和缓存锁**定两个机制来保证复杂内存操作的原子性。


### Java 中如何实现原子操作

java 中可以通过**锁和循环 CAS**的方式实现原子操作

CAS 操作就是利用上文说的处理器提供的 CMPXCHG 指令实现的，是硬件原语。自旋 CAS 就是以一直进行 CAS 操作直到 CAS 成功为止。 java 提供了 atomic 包进行一系列的原子操作。

## Atomic

在 atomic 包中一共 you 有 12 个类，4 中原子更新方式，分别是：
1. 原子更新基本类型
2. 原子更新数组
3. 原子更新引用
4. 原子更新字段

### 原子更新基本类型类
-   `AtomicBoolean` ：原子更新布尔类型。
-   `AtomicInteger` ：原子更新整型。
-   `AtomicLong` ：原子更新长整型。

#### AtomicInteger

AtomicInteger 的常用方法如下：

-   `int addAndGet(int delta)` ：以原子方式将输入的数值与实例中的值（AtomicInteger 里的 value）相加，并返回结果
-   `boolean compareAndSet(int expect, int update)` ：如果输入的数值等于预期值，则以原子方式将该值设置为输入的值。
-   `int getAndIncrement()` ：以原子方式将当前值加 1，注意：这里返回的是自增前的值。
-   `void lazySet(int newValue)` ：最终会设置成 newValue，使用 lazySet 设置值后，可能导致其他线程在之后的**一小段时间内还是可以读到旧的值**。
-   `int getAndSet(int newValue)` ：以原子方式设置为 newValue 的值，并返回旧值。


> Atomic 包提供了三种基本类型的原子更新，但是 Java 的基本类型里还有 char，float 和 double 等。那么问题来了，如何原子的更新其他的基本类型呢？Atomic 包里的类基本都是使用 Unsafe 实现的，Unsafe 只提供了三种 CAS 方法，compareAndSwapObject，compareAndSwapInt 和 compareAndSwapLong，再看 AtomicBoolean 源码，发现其是先把 Boolean 转换成整型，再使用 compareAndSwapInt 进行 CAS，所以原子更新 double 也可以用类似的思路来实现。

### 原子更新数组类
以原子的方式更新数组某个元素，提供一下 3 个类

-   `AtomicIntegerArray` ：原子更新整型数组里的元素。
-   `AtomicLongArray` ：原子更新长整型数组里的元素。
-   `AtomicReferenceArray` ：原子更新引用类型数组里的元素。

`AtomicIntegerArray` 类主要是提供原子的方式更新数组里的整型，其常用方法如下

-   `int addAndGet(int i, int delta)` ：以原子方式将输入值与数组中索引  i 的元素相加。
-   `boolean compareAndSet(int i, int expect, int update)` ：如果当前值等于预期值，则以原子方式将数组位置 i 的元素设置成 update 值。

### 原子更新字段类

如果我们只需要某个类里的某个字段，那么就需要使用原子更新字段类，Atomic 包提供了以下三个类：

-  `AtomicIntegerFieldUpdater` ：原子更新整型的字段的更新器。
-   `AtomicLongFieldUpdater` ：原子更新长整型字段的更新器。
-   `AtomicStampedReference` ：原子更新带有版本号的引用类型。该类将整数值与引用关联起来，可用于原子的更数据和数据的版本号，**可以解决使用 CAS 进行原子更新时，可能出现的 ABA 问题。**

原子更新字段类都是抽象类，每次使用都时候必须使用静态方法 newUpdater 创建一个更新器。**原子更新类的字段的必须使用 public volatile 修饰符。**

## Unsafe

正如其名，Unsafe 提供一些不安全的操作方法，如直接访问系统内存资源，自主管理系统内存资源，这些方法在提高 java 运行效率，增强 java 底层资源的操作能力发挥了很大作用。但由于 Unsafe 类使 Java 语言拥有了类似 C 语言指针一样操作内存空间的能力，这无疑也增加了程序发生相关指针问题的风险。在程序中过度、不正确使用 Unsafe 类会使得程序出错的概率变大，使得 Java 这种安全的语言变得不再“安全”，因此对 Unsafe 的使用一定要慎重。


### 如何使用 Unsafe 类
Unsafe 类为一单例实现，提供静态方法 getUnsafe 获取 Unsafe 实例，**当且仅当调用 getUnsafe 方法的类为引导类加载器所加载时才合法**，否则抛出 SecurityException 异常

我们自己写的应用程序无法直接使用 Unsafe 类，可以通过反射方式使用：

```java
public class UnsafeInstance {  
  
    public static Unsafe reflectGetUnsafe() {  
        try {  
            Field field = Unsafe.class.getDeclaredField("theUnsafe");  
            field.setAccessible(true);  
            return (Unsafe) field.get(null);  
        } catch (Exception e) {  
            e.printStackTrace();  
        }  
        return null;  
    }  
}
```

### Unsafe 功能介绍

Unsafe 提供的 API 大致可分为内存操作、CAS、Class 相关、对象操作、线程调度、系统信息获取、内存屏障、数组操作等几类，下面进行简单介绍：
![](../images/Pasted%20image%2020221011141133.png)

### 内存操作
- 分配内存, 相当于 C++的 malloc 函数
`public native long allocateMemory(long bytes);`

- 扩充内存
`public native long reallocateMemory(long address, long bytes);`

- 释放内存
`public native void freeMemory(long address);`

- 在给定的内存块中设置值
`public native void setMemory(Object o, long offset, long bytes, byte value);`

- 内存拷贝
`public native void copyMemory(Object srcBase, long srcOffset, Object destBase, long destOffset, long bytes);`

- 获取给定地址值，忽略修饰限定符的访问限制。与此类似操作还有: getInt，getDouble，getLong，getChar 等
`public native Object getObject(Object o, long offset);`

- 为给定地址设置值，忽略修饰限定符的访问限制，与此类似操作还有: putInt,putDouble，putLong，putChar 等
`public native void putObject(Object o, long offset, Object x);`
`public native byte getByte(long address);`

- 为给定地址设置 byte 类型的值（当且仅当该内存地址为 allocateMemory 分配时，此方法结果才是确定的）
`public native void putByte(long address, byte x);`

#### 为什么会用到堆外内存
通常我们使用 new 关键词构造的对象占用的都是 jvm 堆内的空间，由 jvm 统一管理。与之相对的就是堆外内存，jvm 无法管理，回收。使用 Unsafe 提供的方法可以对堆外的内存进行管理。那么我们什么场景下会使用堆外内存呢？
##### 改善垃圾回收性能
由于堆外内存是由操作系统管理，而不是 jvm，当我们使用堆外内存时，可以保持降低堆内内存的使用，减少垃圾回收停顿堆应用的影响，比如在上传大文件时，可以把文件对象分配到堆外内存。
##### 提升程序 I/O 操作的性能
通常在 IO 通信过程中，存在堆内内存到堆外内存的数据拷贝过程，-   对于需要频繁进行内存间数据拷贝且生命周期较短的暂存数据，都建议存储到堆外内存。



### CAS 相关

如下源代码：
```java
* CAS

* @param o 包含要修改field的对象

* @param offset 对象中某field的偏移量

* @param expected 期望值

* @param update 更新值

* @return true | false

*/

public final native boolean compareAndSwapObject(Object var1, long var2, Object var4, Object var5);

public final native boolean compareAndSwapInt(Object var1, long var2, int var4, int var5);

public final native boolean compareAndSwapLong(Object var1, long var2, long var4, long var6);
```

#### 应用场景

atomic 包中各类原子操作，都是对 CAS 的应用


### 线程调度

包括线程挂起、恢复、锁机制等方法。

```java
//取消阻塞线程

public native void unpark(Object thread);

//阻塞线程

public native void park(boolean isAbsolute, long time);

//获得对象锁（可重入锁）
@Deprecated
public native void monitorEnter(Object o);

//释放对象锁
@Deprecated
public native void monitorExit(Object o);

//尝试获取对象锁
@Deprecated
public native boolean tryMonitorEnter(Object o);
```

方法 park、unpark 即可实现线程的挂起与恢复，将一个线程进行挂起是通过 park 方法实现的，调用 park 方法后，线程将一直阻塞直到超时或者中断等条件出现；unpark 可以终止一个挂起的线程，使其恢复正常。

####  应用场景
Java 锁和同步器框架的核心类 `AbstractQueuedSynchronizer`，就是通过调用 `LockSupport.park()` 和 `LockSupport.unpark()` 实现线程的阻塞和唤醒的，而 LockSupport 的 park、unpark 方法实际是调用 Unsafe 的 park、unpark 方式来实现。

### 内存屏障

在 Java 8 中引入，用于定义内存屏障（也称内存栅栏，内存栅障，屏障指令等，是一类同步屏障指令，是 CPU 或编译器在对内存随机访问的操作中的一个同步点，使得此点之前的所有读写操作都执行后才可以开始执行此点之后的操作），避免代码重排序