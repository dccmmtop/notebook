---
title: 并发编程之Semaphore和CountDownLatch的用法
date: 2022-10-10 10:40:28
tags: [java]
---

# Semaphore 

Semaphore 是信号量的意思，它的作用是控制访问特定资源的**线程数目**，底层依赖 AQS 的状态 State，是在生产当中比较常用的一个工具类。

可以理解为许可证，或者令牌。线程想要访问某部分资源时，必须先获取一个许可证，才能访问，否则等待，一个经典的应用场景是服务限流(Hystrix 里限流就有基于信号量方式)，

## 重要方法

### 构造方法
```java
// 构造方法1
// permits 许可证的数量，默认是非公平的方式抢占许可证，许可证用完之后，
// 再来的线程要等待其他线程释放许可证
public Semaphore(int permits) {  
    sync = new NonfairSync(permits);  
}

// 构造方法2
// 同上，可以指定公平还是非公平
public Semaphore(int permits, boolean fair) {
	sync = fair ? new FairSync(permits) : new NonfairSync(permits);
}
```

### 获取许可证

####  acquire() 

此过程是**阻塞**的，它会一直等待许可证，直到发生以下任意一件事：

- 当前线程获取了 1 个可用的许可证，则会停止等待，继续执行。
- 当前线程**被中断**，则会抛出 InterruptedException 异常，并停止等待，继续执行。

#### acquire(int permits)

此过程是**阻塞**的，它会一直等待许可证，直到发生以下任意一件事：
- 当前线程获取了 n 个可用的许可证，则会停止等待，继续执行。
- 当前线程**被中断**，则会抛出 InterruptedException 异常，并停止等待，继续执行

#### acquireUninterruptibly(int permits)

此过程是**阻塞**的，它会一直等待许可证，直到发生以下任意一件事：
- 当前线程获取了 1 个可用的许可证，则会停止等待，继续执行。

与前两个的区别是，它不理会中断

#### acquireUninterruptibly(int permits)

此过程是**阻塞**的，它会一直等待许可证，直到发生以下任意一件事：
- 当前线程获取了 n 个可用的许可证，则会停止等待，继续执行。
它不理会中断

#### tryAcquire()

**当前线程尝试去获取 1 个许可证。**

此过程是**非阻塞**的，它只是在方法调用时进行一次尝试。如果当前线程获取了 1 个可用的许可证，则会停止等待，继续执行，并返回 true。如果当前线程没有获得这个许可证，也会停止等待，继续执行，并返回 false。

#### tryAcquire(int permits)
当前线程尝试去获取 permits 个许可证。

此过程是**非阻塞**的，它只是在方法调用时进行一次尝试。如果当前线程获取了 permits 个可用的许可证，则会停止等待，继续执行，并返回 true。如果当前线程没有获得 permits 个许可证，也会停止等待，继续执行，并返回 false。

#### tryAcquire(long timeout, TimeUnit unit)

当前线程在**限定时间内**，阻塞的尝试去获取 1 个许可证。

此过程是阻塞的，它会一直等待许可证，直到发生以下任意一件事：

- 当前线程获取了可用的许可证，则会停止等待，继续执行，并返回 true。
- 当前线程等待时间 timeout 超时，则会停止等待，继续执行，并返回 false。
- 当前线程在 timeout 时间内被中断，则会抛出 InterruptedException 一次，并停止等待，继续执行。

#### tryAcquire(int, long, TimeUnit)
当前线程在**限定时间内**，阻塞的尝试去**获取 permits 个**许可证。

此过程是阻塞的，它会一直等待许可证，直到发生以下任意一件事：

- 当前线程获取了可用的 permits 个许可证，则会停止等待，继续执行，并返回 true。
- 当前线程等待时间 timeout 超时，则会停止等待，继续执行，并返回 false。
- 当前线程在 timeout 时间内被中断，则会抛出 InterruptedException 一次，并停止等待，继续执行。

#### drainPermits()
**当前线程获得剩余的所有可用许可证**

### 释放许可证
#### release()
当前线程释放一个许可证
#### release(int)
当前线程释放 n 个许可证

### 示例
```java
import java.util.Date;  
import java.util.concurrent.Semaphore;  
  
public class SemaphoreRunner {  
    public static void main(String[] args) {  
        Semaphore semaphore = new Semaphore(2);  
        for (int i = 0; i < 10; i++) {  
            new Thread(new Task(semaphore, "任务:" + i)).start();  
        }  
    }  
  
    static class Task extends Thread {  
        Semaphore semaphore;  
  
        public Task(Semaphore semaphore, String tname) {  
            this.semaphore = semaphore;  
            this.setName(tname);  
        }  
  
        @Override  
        public void run() {  
            try {  
                semaphore.acquire();  
                System.out.println(this.getName() + "获得许可证 at time:" + new Date());  
                Thread.sleep(3000);  
                semaphore.release();  
            } catch (InterruptedException e) {  
                e.printStackTrace();  
            }  
  
        }  
    }  
}
```

结果:

```txt
任务:0获得许可证 at time:Mon Oct 10 11:42:33 CST 2022
任务:1获得许可证 at time:Mon Oct 10 11:42:33 CST 2022
任务:3获得许可证 at time:Mon Oct 10 11:42:36 CST 2022
任务:2获得许可证 at time:Mon Oct 10 11:42:36 CST 2022
任务:4获得许可证 at time:Mon Oct 10 11:42:39 CST 2022
任务:5获得许可证 at time:Mon Oct 10 11:42:39 CST 2022
任务:7获得许可证 at time:Mon Oct 10 11:42:42 CST 2022
任务:6获得许可证 at time:Mon Oct 10 11:42:42 CST 2022
任务:9获得许可证 at time:Mon Oct 10 11:42:45 CST 2022
任务:8获得许可证 at time:Mon Oct 10 11:42:45 CST 2022
```

可以看出当设置 2 个许可证时，同时只有两个线程执行
# CountDownLatch 与 CyclicBarrier

CountDownLatch 这个类能够使一个线程等待其他线程完成各自的工作后再执行。例如，应用程序的主线程希望在负责启动框架服务的线程已经启动所有的框架服务之后再执行, **它强调的是一个线程等待其他多个线程**

CountDownLatch 其实可以把它看作一个计数器，只不过这个计数器的操作是原子操作，同时只能有一个线程去操作这个计数器，也就是同时只能有一个线程去减这个计数器里面的值。可以向 CountDownLatch 对象设置一个初始的数字作为计数值，任何调用这个对象上的 await()方法都会阻塞，直到这个计数器的计数值被其他的线程减为 0 为止。所以在当前计数到达零之前，await 方法会一直受阻塞。之后，会释放所有等待的线程，await 的所有后续调用都将立即返回。这种现象只出现一次——**计数无法被重置**

CyclicBarrier **允许一组线程互相等待**，直到到达某个公共屏障点 (common barrier point)。在涉及一组固定大小的线程的程序中，这些线程必须不时地**互相等待**，此时 CyclicBarrier 很有用。因为该 barrier 在释放等待线程后可以重用，所以称它为**循环的 barrier**， CyclicBarrier 可以用来模拟并发，类似于 Jmeter, 只有多个线程都到达要并发的位置时，再统一开始执行，就像多个线程运行到一个栅栏前等待，然后把栅栏移除，多个线程同时运行。移除的时机是多个线程全部到达栅栏前

### 区别


![](../images/Pasted%20image%2020221010143333.png)


### 重要方法
**CountDownLatch**

```java
public void await() throws InterruptedException {  
    //调用await()方法的线程会被挂起，它会等待直到count值为0才继续执行  
}  
public boolean await(long timeout, TimeUnit unit) throws InterruptedException {  
    //和await()类似，只不过等待一定的时间后count值还没变为0的话就会继续执行  
}  
  
public void countDown() {  
    //将count值减1  
}
```

**使用示例**
```java
public class CountDownlatchRunner {  
    public static void main(String[] args) throws InterruptedException {  
        CountDownLatch countDownLatch = new CountDownLatch(5);  
        for(int i=0;i<5;i++){  
            new Thread(new ReadNum(i,countDownLatch)).start();  
        }  
        // 等待所有线程结束
        countDownLatch.await();  
        System.out.println("线程执行结束。。。。");  
    }  
  
    static class ReadNum  implements Runnable{  
        private int id;  
        private CountDownLatch latch;  
        public ReadNum(int id,CountDownLatch latch){  
            this.id = id;  
            this.latch = latch;  
        }  
        @Override  
        public void run() {  
            synchronized (this){  
                System.out.println("id:"+id);  
                latch.countDown();  
                System.out.println("线程组任务"+id+"结束，其他任务继续");  
            }  
        }  
    }  
}
```

**CyclicBarrier**

提供了两个构造器
```java

// 指定了N个线程互相等待
public CyclicBarrier(int parties) { }
// 指定N个线程在任务 barrierAction  处互相等待
public CyclicBarrier(int parties, Runnable barrierAction) { } 
```


等待方法:
```java
public int await() throws InterruptedException, BrokenBarrierException {
        //挂起当前线程，直至所有线程都到达barrier状态再同时执行后续任务；
}
public int await(long timeout, TimeUnit unit)throws InterruptedException,BrokenBarrierException,TimeoutException {
//让这些线程等待至一定的时间，如果还有线程没有到达barrier状态
//就直接让到达barrier的线程执行后续任务
}
```
**示例**


```java
public class CyclicBarrierTest {
	public static void main(String[] args) throws InterruptedException {
		CyclicBarrier cyclicBarrier = new CyclicBarrier(5, new Runnable() {
			@Override
			public void run() {
				System.out.println("线程组执行结束");
			}
		});
		for (int i = 0; i < 5; i++) {
			new Thread(new ReadNum(i,cyclicBarrier)).start();
		}
		//CyclicBarrier 可以重复利用，
		// 这个是CountDownLatch做不到的
//        for (int i = 11; i < 16; i++) {
//            new Thread(new readNum(i,cyclicBarrier)).start();
//        }
	}
	static class ReadNum  implements Runnable{
		private int id;
		private CyclicBarrier cyc;
		public readNum(int id,CyclicBarrier cyc){
			this.id = id;
			this.cyc = cyc;
		}
		@Override
		public void run() {
			synchronized (this){
				System.out.println("id:"+id);
				try {
				// 线程等待，直到5各线程都运行到这里再一起执行
					cyc.await();
					System.out.println("线程组任务" + id + "结束，其他任务继续");
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		}
	}
}

```
