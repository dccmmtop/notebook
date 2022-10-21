---
title: java常量池
date: 2022-09-15 10:05:51
tags: [java]
---

## Class常量池
Class常量池可以理解为class文件中的资源仓库，class 文件中除了包含类信息，方法，字段，接口信息之外还有常量池信息，用于存放编译期生成的各种字面量和符号引用。


如下:
![](../images/Pasted%20image%2020220917111234.png)


常量池主要包含两大类常量: 字面量和符号引用。

## 字面量
字面量就是有字符串和数字等构成的常量。

字面量只能以右值出现，int a = 1, a 是左值，1 是右值


```java
int a =1;
int b =2;
String c= "abc"；
String d= "abc"；
```

1 2  "abc" 都是常量

## 符号引用

符号引用是编译原理中概念，是相对于直接引用来说的，主要包括一三类常量:
- 类和接口的全限定名
- 字段的名称和描述符
- 方法的名称和描述符

上面的 a b就是字段名 ，是符号引用。 还有包名+类名 组成的类的全限定名，方法名，以及() 都是符号引用

## 运行常量池

存在class 文件的常量都是静态信息，只有到运行时被加载到内存中，这些符号才有具体的内存地址，这些常量一旦被加载内存中，就变成运行常量池，对应的符号引用在程序运行时，会被加载到内存区域的代码直接引用，也就我们说的动态链接，例如： compute() 这个符号引用在运行时就会被转化成compute()方法具体代码在内存中的地址，


## 字符串常量池

在内存中专门存放字符串字面量的区域称作字符串常量池，那么除了把对象放入堆中之外。还需要独立的区域存放字符串字面量呢？


主要是为了性能：
- 字符串的分配和其他对象分配一样，耗费高昂的时间与空间代价，作为最基础的数据类型，需要大量频繁的创建，极大影响了程序的性能



JVM 为了提高性能和减少内存开销，在实例化字符串常量的时候进行了一些优化：
1. 为字符串开辟一个字符串常量池，类似于缓存
2. 创建字符串常量时，首先查询字符串常量池是否已经存在
3. 若存在该字符串，直接返回引用示例，不存在，实例化该字符串并放入池中

### 什么时候会把字符串常量放入常量池

1. 直接赋值字符串
```java
String s = "hello"；
```

**这种方式创建的字符串只会在常量池中，不会在堆中额外创建一个对象** 

当再次创建字符串 `String s1 = "hello"` 时，先去常量池中通过 `equals(key)` 方法判断是否有相同的对象，如果有直接返回对象在常量池的引用。如果没有会在常量池新新建对象，再返回引用

所以有如下结果:

```java
String s = "hello"；
String s1 = "hello"；
System.out.println( s == 1) // true. s 和 s1 地址一样
```


2. new String()

```java
String s = new String("hello");
```

这中方式创建字符串会保证常量池中和堆中都有这个对象，最后返回堆中的地址:
![](../images/Pasted%20image%2020220917115755.png)

3. intern 方法
```java
String s = new String("hello")；
String s1 = s.intern();
System.out.println(s == s1) // false
```
String intern 方法是一个 native 方法，如果池中已经包含一个等于此 String 对象的字符串，则返回池中的字符串，**否则将intern 返回的引用指向当前字符串（在 jdk 1.6 中，需要将s1字符串复制到常量池中）**

在第一种情况，`String s = "hello"` 会将 `hello` 放入常量池中， 第二种情况 `String s = new String("hello")` 也会将 `hello` 放入常量池中，那么什么情况下常量池会没有我们要取的字符串呢？

常量池存放的一定是不可变的字面量, 无论是 `String s = "hello"` 还是 `String s = new String("hello")` 都有一个明确的字面量: `hello` 如果是下面这种情况:
```java
String s = new String("hello") + new String("World")
String s1 = "helloWorld"；
System.out.println(s == s1) // false
System.out.println(s == s.intern()) // true

```
常量池中有 `hello` 和 `World` 但是没有 `helloWorld`， 因为在代码中没有明确的`helloWorld`字面量，所以 s != s1, 常量池中没有 `helloWorld` 字面量，所以 `s.intern()` 返回的是堆中的地址，故而 `s == s.intern()`



再看下面一种情况:

```java
String s = "hello" + "World"；
String s1 = "helloWorld"； 
System.out.println(s == s1) // true
```

代码中也没有明确的`helloWorld` 字面量， 为什么 s == s1 呢， 因为 `hello` 和 `World` 都是**不可变**的字面量，而不是一个引用，在 `String s = "hello" + "World"` 时， 编译器可以优化成 `s = "helloWorld"` ， 所以 s == s1 ，那为什么 `String s = new String("hello") + new String("World")` 不会被编译器优化呢？ 因为 `new String("hello")` 是一个对象，返回的是引用，而不是一个不会变化的字面量，后面这个引用地址可能会指向其他的对象，优化后可能会出现错误。同理：
```java
String s = "hello";
String s1 = "World"；
String s2 = s + s1; // 不会编译器优化成 "helloWorld"
String s3 = "helloWorld";
System.out.println(s3 == s2); // false
```

但是被 final 修饰的变量可以被优化，因为它不会发生变化了：

```java
final String s = "hello"; // s 不会再被重新赋值
final String s1 = "World"；
String s2 = s + s1; // 编译器优化成 "helloWorld"
String s3 = "helloWorld";
System.out.println(s3 == s2); // true
```

再看下面一种情况：


```java
final String s = getHello(); // s 虽然不能再被重新赋值，但getHello() 方法返回的值可能会改变
final String s1 = "World"；
String s2 = s + s1; // 不会编译器优化成 "helloWorld"
String s3 = "helloWorld";
System.out.println(s3 == s2); // false

public String getHello(){
    return "hello"
}
```

s 的值无法再编译器确定，所以无法优化成字面量

再看最后一个例子：
```java

String s1 = new String("hello") + new String("World")；
System.out.println(s1 == s1.intern()) // true

String s = new String("ja") + new String("va")；
System.out.println(s == s.intern()) // false
```
为什么同样的写法，结果却不一样呢？

intern() 方法优先返回常量池中的地址, 常量池不存在时，再返回堆中的地址， 第一个 s1 != s1.intern() 是符合我们直觉的，因为常量池中没有 helloWorld , 但是第二个 s == s.intern() 为false 就说不通了，难道常量池已经有 `java` 这个字面量了吗？ 是的， java 这个关键词，在jvm 启动或类加载期间肯定有 `java` 这个字符串已经放入到常量池中了， s.inern() 返回的是常量池中的地址.

## 八种基本类型的包装类和对象池  
java中基本类型的包装类的大部分都实现了常量池技术(严格来说应该叫对象池，在堆上)，这些类是   Byte,Short,Integer,Long,Character,Boolean,另外两种浮点数类型的包装类则没有实现。另外   Byte,Short,Integer,Long,Character这5种整型的包装类也只是在对应值小于等于127时才可使用对象池，也即对象不负责创建和管理o大于127的这些类的对象。因为一般这种比较小的数用到的概率相对较大
```java
public class Test {

    public static void main(String[] args) {
        //5种整形的包装类Byte,Short,Integer,Long,Character的对象，  
        //在值小于127时可以使用对象池  
        Integer i1 = 127;  //这种调用底层实际是执行的Integer.valueOf(127)，里面用到了IntegerCache对象池
        Integer i2 = 127;
        System.out.println(i1 == i2);//输出true  

        //值大于127时，不会从对象池中取对象  
        Integer i3 = 128;
        Integer i4 = 128;
        System.out.println(i3 == i4);//输出false  
        
        //用new关键词新生成对象不会使用对象池
        Integer i5 = new Integer(127);  
        Integer i6 = new Integer(127);
        System.out.println(i5 == i6);//输出false 

        //Boolean类也实现了对象池技术  
        Boolean bool1 = true;
        Boolean bool2 = true;
        System.out.println(bool1 == bool3);//输出true  

        //浮点类型的包装类没有实现对象池技术  
        Double d1 = 1.0;
        Double d2 = 1.0;
        System.out.println(d1 == d2);//输出false  
    }
} 
```
