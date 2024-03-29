---
title: 并发编程AQS原理
date: 2022-10-06 15:14:59
tags: [java]
---

JDK1.5以前只有synchronized同步锁，并且效率非常低，大神Doug Lea自己写了一套并发框架，这套框架的核心就在于AbstractQueuedSynchronizer类（即AQS），性能非常高，所以被引入JDK包中，即JUC。那么AQS是怎么实现的呢？本篇就是对AQS及其相关组件进行分析，了解其原理。

## AQS 的应用
我们经常使用并发包中的阻塞队列(ArrayBlockingQueue), 可重入锁（ReentrantLock），线程栅栏（CountDownLatch）等一些工具底层都是由AQS实现的

## AQS 大致结构
![](../images/Pasted%20image%2020221006153454.png)

## ReentrantLock 实现原理

ReentrantLock 使用简单，我们就以这个类为切入口，学习一下如何利用 AQS 实现加锁释放锁的功能，以及公平和非公平锁实现的差别.

### 加锁

查看 ReentrantLock 的构造方法： 

```java
// 无参构造器默认构造一个非公平锁
public ReentrantLock() {  
    sync = new NonfairSync();  
}  

// 可以指定使用公平锁还是非公平锁
public ReentrantLock(boolean fair) {  
    sync = fair ? new FairSync() : new NonfairSync();  
}
```

由此可知，ReentrantLock 的公平锁和非公平锁分别是由 `FairSync`  和 `NonfairSync`实现的，

由下面的结构图可知，`FairSync ` 和 `NonfairSync ` 都是继承至 `Sync` ,而 `Sync` 又是继承 AQS
![](../images/Pasted%20image%2020221006160005.png)

非公平锁加锁的代码:
```java
// 非公平锁
static final class NonfairSync extends Sync {
  private static final long serialVersionUID = 7316153563782823691L;
  // 获取锁
  final void lock() {
    // 假设t1 线程正在尝试获取锁。
    // CAS算法，把 state 从0修改为1，state 表示当前被加锁的次数
    // 从0变成1，表示t1第一次尝试获取锁
    if (compareAndSetState(0, 1))
      // 如果修改成功，就把t1设置成正在持有锁的线程
      setExclusiveOwnerThread(Thread.currentThread());
    else
      // 未获取到锁...
      acquire(1);
  }
}
```

accquire(1) 实现:

```java
public final void acquire(int arg) {
  // tryAcquire(arg)：尝试抢锁
  // addWaiter(Node.EXCLUSIVE)，将当前线程构造成一个队列节点，并入队
  // acquireQueued（...） 将线程挂起，维护线程节点的状态
  if (!tryAcquire(arg) &&
      acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
    selfInterrupt();
}

```

大致意思就是，线程再抢一次锁，如果失败了，就构造一个线程节点，然后把节点放入队列，将线程挂起，等待被唤醒

再次抢锁代码: tryAcquire(arg):

```java
// 非公平锁尝试获取锁
final boolean nonfairTryAcquire(int acquires) {  
  final Thread current = Thread.currentThread(); 
  // 获取已经加锁的次数
  int c = getState();  
  // 没有线程持有锁
  if (c == 0) {  
    // 直接抢锁。没有判断队列中是否有线程排队，插队，不公平
    if (compareAndSetState(0, acquires)) { 
      // 抢锁成功
      setExclusiveOwnerThread(current);  
      return true;            }  
  }  
  // 正在有线程持有锁，并且这个线程是自己(t1)
  else if (current == getExclusiveOwnerThread()) {  
    // t1 已经获取到锁，无需再次获取锁，只需把锁的次数增加即可
    int nextc = c + acquires;  
    if (nextc < 0) // overflow  
      throw new Error("Maximum lock count exceeded");  
    // 设置锁的次数
    setState(nextc);  
    return true;        
  }  
  return false;  
}
```

#### 公平锁的实现

```java
protected final boolean tryAcquire(int acquires) {
  final Thread current = Thread.currentThread();
  int c = getState();
  if (c == 0) {
    // hasQueuedPredecessors： 当线程尝试获取锁时，不是直接去抢，
    //    而是先判断是否存在队列，如果存在就不抢了，返回抢锁失败
    if (!hasQueuedPredecessors() &&
        compareAndSetState(0, acquires)) {
      setExclusiveOwnerThread(current);
      return true;
    }
  }
  else if (current == getExclusiveOwnerThread()) {
    int nextc = c + acquires;
    if (nextc < 0)
      throw new Error("Maximum lock count exceeded");
    setState(nextc);
    return true;
  }
  return false;
}
// 是否存在队列并且(下一个待唤醒的线程不是本线程(准备重入锁))
public final boolean hasQueuedPredecessors() {
  // The correctness of this depends on head being initialized
  // before tail and on head.next being accurate if the current
  // thread is first in queue.
  Node t = tail; // Read fields in reverse initialization order
  Node h = head;
  Node s;
  return h != t &&
    ((s = h.next) == null || s.thread != Thread.currentThread());
}
```

于非公平锁相比，只有`tryAcquire` 方法的区别，



#### 为什么需要再次抢锁?

因为抢锁失败有两种原因，1是当前线程确实没有获取到锁。2是当前线程之前已经获取到锁了，还想再获取一次。

对于1这种情况，让线程再抢一次，可能会抢到锁，就不用调用系统api把线程挂起，提高性能

对于2， 只需改变加锁的次数，就可以标记当前线程已经加锁的次数了，再释放锁时，对应的减成0就可以认为当前线程已经完全释放锁了，这就是可重入锁的实现原理

#### 构造队列节点及入队

下面看一下构造线程节点的实现:  

addWaiter()

```java
private Node addWaiter(Node mode) {
  // 以当前线程为参数，构造一个新的 node，记作当前线程节点 
  Node node = new Node(Thread.currentThread(), mode);
  // 在最开始，tail 和 pred 肯定都是null,
  Node pred = tail;
  // 最开始不会进入下面，只有队列不为空时，才会进入
  if (pred != null) {
    node.prev = pred;
    // 将节点加入队尾
    if (compareAndSetTail(pred, node)) {
      pred.next = node;
      return node;
    }
  }
  // 而是由 enq(node) 构造节点
  enq(node);
  return node;
}
private Node enq(final Node node) {
  // 开始了循环
  for (;;) {
    Node t = tail;
    // 最开始队列是空的。只有第一次循环会进入
    if (t == null) { // Must initialize
      // 构造了一个空的node节点当作队列的头节点
      if (compareAndSetHead(new Node()))
        tail = head;
    } else {
      // 第二次及后面的循环会走到这里
      // 先设置当前节点的前驱节点是 队尾节点。
      node.prev = t;
      // 用CAS算法把当前节点 设置成队尾
      if (compareAndSetTail(t, node)) {
        // 这样上一次的队尾t就不是队尾了，t 就有了后继节点node
        t.next = node;
        return t;
      }
    }
  }
}
```

经过`addWaiter(Node node)` 方法后，队列中至少存在两个节点，第一个就是必须的空节点，不包含线程信息，第二个才是真正待执行的线程节点，作者为什么这么做呢？

我认为，队列中存放的不仅是待唤醒的线程节点，而是所有等待运行和正在运行的线程节点，因为已经拿到锁的正在运行的线程不需要被唤醒，所以也就不需要存储线程信息了。并且这个正在运行的线程节点是队列中的头节点

#### 线程挂起

下面就要看`acquireQueued` 方法了

```java
final boolean acquireQueued(final Node node, int arg) {
  boolean failed = true;
  try {
    boolean interrupted = false;
    // 开始循环抢锁
    for (;;) {
      // 获取当前接节点的前驱节点
      final Node p = node.predecessor();
      // 如果前驱节点是头节点，并且抢锁成功
      if (p == head && tryAcquire(arg)) {
        // 把当前节点设置成头节点，setHead会清空node中的线程信息，和初始化时设置的空头节点一样
        setHead(node);
        // 断开前驱节点，旧的 head 会被垃圾回收
        p.next = null; // help GC
        failed = false;
        return interrupted;
      }
      //走到这里说明不是头节点，或者抢锁失败
      // shouldParkAfterFailedAcquire(p, node): 
      //    检查 node 是否是可唤醒的（waitStatus == -1）,如果是，返回true
      //    如果node不是可唤醒的，并且node没有被取消掉，则将node设置设置为可唤醒，返回false,
      //    下一次循环时就会返回false
      // parkAndCheckInterrupt(): 挂起线程
      if (shouldParkAfterFailedAcquire(p, node) && parkAndCheckInterrupt())
        interrupted = true;
    }
  } finally {
    // 这个判断不会走，可以认为 failed 和 interrupted 标识这里无用。
    // 程序能走到这里，说明 (p ==head && tryQcquire(arg)) 为true，那么 failed 和 interupted 恒为false
    // 否则就会陷在循环中，无法到 finally 中。
    if (failed)
      cancelAcquire(node);
  }
}

// 把node设置为队列的头节点
private void setHead(Node node) {
  head = node;
  // 清空了线程信息
  node.thread = null;
  node.prev = null;
}
```

shouldParkAfterFailedAcquire(Node pred, Node node)

```java
// 接受两个参数，一个是当前节点的前驱节点，一个是当前节点
/**
* 这里使用前驱节点中的waitStatus状态来判断当前节点是否可以被唤醒。
*/
private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
  // 前驱节点的状态
  int ws = pred.waitStatus;
  // 如果是可唤醒的，直接返回true
  if (ws == Node.SIGNAL)
    return true;
  if (ws > 0) {
    // 标识前驱节点已经取消锁竞争，跳过这个前驱节点，继续向前查找
    do {
      // 一直向前找
      node.prev = pred = pred.prev;
    } while (pred.waitStatus > 0); // 到不是已取消的节点为止
    // 设置有效的前驱节点
    pred.next = node;
  } else {
    // 将前驱节点的 ws 设置可唤醒的
    compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
  }
  return false;
}
```

## 释放锁

释放锁的逻辑比较简单，

1. 减少加锁的次数(state)，如果state == 0, 代表当前线程可以释放锁，然后把持有锁的线程标记为空
2. 唤醒队列中第一个待运行的线程也就是第二个节点，因为第一个节点是当前已获取到锁正在运行线程

```java
public final boolean release(int arg) {
  // 释放锁
  if (tryRelease(arg)) {
    Node h = head;
    // 头节点不为空，且头节点的waitStatus不是默认状态
    if (h != null && h.waitStatus != 0)
      //传入的是头节点
      unparkSuccessor(h);
    return true;
  }
  return false;
}


// 释放锁
protected final boolean tryRelease(int releases) {
  int c = getState() - releases;
  if (Thread.currentThread() != getExclusiveOwnerThread())
    throw new IllegalMonitorStateException();
  boolean free = false;
  if (c == 0) {
    free = true;
    setExclusiveOwnerThread(null);
  }
  setState(c);
  return free;
}

private void unparkSuccessor(Node node) {

  int ws = node.waitStatus;
  if (ws < 0)
    // 再次将ws 置为0，这里暂时不清楚为什么重置状态
    compareAndSetWaitStatus(node, ws, 0);
  // 获取传入节点的后继节点
  Node s = node.next;
  if (s == null || s.waitStatus > 0) {
    s = null;
    for (Node t = tail; t != null && t != node; t = t.prev)
      if (t.waitStatus <= 0)
        s = t;
  }
  // 唤醒后继节点
  if (s != null)
    LockSupport.unpark(s.thread);
}
```

## 获取锁的流程图

![](../images/Pasted%20image%2020221007094312.png)

## 队列中节点状态
![](../images/Pasted%20image%2020221009092730.png)

