---
title: ArrayList和CopyOnWriteArrayList
date: 2022-10-18 17:08:33
tags: [java]
---

# ArrayList
## ArrayList 的保护机制
```java
for(String str : list){
    if(str.equals("123")){
        list.remove(str);   //抛出异常
    }
}
```

这里的 `foreach` 语法糖实际上调用了 ArrayList 的迭代器类。如下：
![](../images/Pasted%20image%2020221018171628.png)

如果在开始迭代的时候数组中有 5 个元素，但是在迭代中移除了一个元素，数组实际上还有 4 个元素，但是还是会遍历第五个元素，这就导致了下标越界错误，ArrayList 不允许这种异常发生。还有在多线程下场景下，一个线程遍历这个 ArrayList , 另一个线程移除数组中的某个元素，也会发生 `ConcurrentModificationException` 异常。
## fail-Fast 机制
这个机制就是 fail-Fast 机制，快速失败系统，通常设计用于停止有缺陷的过程，这是一种理念，在进行系统设计时优先考虑异常情况，一旦发生异常，直接停止并上报。

```java
public int divide(int divisor, int dividend){
    if (dividend == 0) {
        throw new RuntimeException("被除数不能为 0");    //这里就是 fail-fast 的体现
    }
    return divisor / dividend;
}

```


## 保护机制的实现原理

在 ArrayList 中有一个成员变量： `modCount`, 它是从 `AbstractList` 继承来的， `modCount` 记录数组每次写操作的次数。当像数组增加或移除一个元素，其值加 1，初始值为 0，在开始遍历的时候，会记录当下数组的 `modCount` 值为 `expectedModCount`，遍历每个元素时都会比较 `modCount` 和 `expectedModCount` 两个值，如果不同，就会抛出异常，代表着在遍历的时候修改了数组。如下：
![](../images/Pasted%20image%2020221018173604.png)

## 怎么样才可以在循环中修改数组？
如果我们每次向数组中添加或删除元素时，同步修改 `exceptedModCount` 就不会抛出异常了，ArrayList 没有直接提供这种方法，而是把这种方法委托给迭代器了：
![](../images/Pasted%20image%2020221018174601.png)

 ![](../images/Pasted%20image%2020221018174633.png)
 
所以我们可以这样做：

```java
Iterator <String> iterator = list.iterator();
while(iterator.hasNext()){
    String str = iterator.next();
    iterator.remove();   //正确做法
}
```


# CopyOnWriteArrayList

CopyOnWriteArrayList 是 ArrayList 的线程安全版本，读取无锁，写时有锁。适用于 写少读多的场景，会有不一致的现象


## 实现原理
见名知意—— 写时复制， 当线程在数组上移除，添加元素时，先加锁，将原数组复制一份，然后基于副本操作，最后将已经更改的副本覆盖元数组，释放锁。

其内部有一个 `ReentranLock` 来控制锁的获取和释放。

先看一下内部结构图：
![](../images/Pasted%20image%2020221018180738.png)

### get 方法 

![](../images/Pasted%20image%2020221018181025.png)

可以看到get方法非常简单，直接获取内部数组第i个元素，没有其他加锁的操作

### add 方法
![](../images/Pasted%20image%2020221018181333.png)

一些其他方法都是这种套路，不再一一罗列。

## 存在的问题

利用了空间换时间的思想提高性能，因为在每一步的写操作都复制了一个副本，如果数组比较大，就会导致内存占用急剧增加，引发频繁 full GC,从而影响系统性能。
### 如何解决
我们可以利用 ReenTranLock 自定义一个线程安全的ArrayList, 分别定义一个 读锁和写锁，读写、写写 互斥。 读读不互斥。避免这种数组的拷贝