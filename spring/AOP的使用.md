---
title: AOP 的使用
date: 2022-11-27 17:08:10
tags: [spring]
---

### 声明切点@Poincut

把切点声明成一个方法，便于重用

@Poincut 的使用格式如下：

```java
@Poincut("PCD") // 切点表达式 表示对哪些方法进行增强
public void pc(){} // 切点签名，返回值必须为 void
```

### 10 种切点表达式

AspectJ 的切点指示符 AspectJ pointcut designators (PCD) ，也就是俗称的切点表达式，Spring 中支持 10 种，如下表：

| 表达式类型    | 作用                                                                                | 匹配规则                                                                                          |
| ------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `execution`   | 用于匹配方法执行的连接点                                                            |                                                                                                   |
| `within`      | 用于匹配指定类型内的方法执行                                                        | within(x) 匹配规则 target.getClass().equals(x)                                                    |
| `this`        | 用于匹配当前 AOP 代理对象类型的执行方法，包含引入的接口类型匹配                     | this(x) 匹配规则：x.getClass.isAssingableFrom(proxy.getClass)                                     |
| `target`      | 用于匹配当前目标对象类型的执行方法，不包括引入接口的类型匹配                        | target(x) 匹配规则：x.getClass().isAssignableFrom(target.getClass());                             |
| `args`        | 用于匹配当前执行的方法传入的参数为指定类型的执行方法                                | 传入的目标位置参数。getClass().equals(@args（对应的参数位置的注解类型）)!= null                   |
| `@target`     | 用于匹配当前目标对象类型的执行方法，其中目标对象持有指定的注解                      | target.class.getAnnotation（指定的注解类型） != null                                              |
| `@args`       | 用于匹配当前执行的方法传入的参数持有指定注解的执行                                  | 传入的目标位置参数。getClass().getAnnotation(@args（对应的参数位置的注解类型）)!= null            |
| `@within`     | 用于匹配所有持有指定注解类型内的方法                                                | 被调用的目标方法 Method 对象。getDeclaringClass().getAnnotation(within 中指定的注解类型） != null |
| `@annotation` | 用于匹配当前执行方法持有指定注解的方法                                              | target.getClass().getMethod("目标方法名").getDeclaredAnnotation(@annotation（目标注解）)!=null    |
| `bean`        | Spring AOP 扩展的，AspectJ 没有对应的指示符，用于匹配特定名称的 Bean 对象的执行方法 | ApplicationContext.getBean("bean 表达式中指定的 bean 名称") != null                               |

简单介绍下 AspectJ 中常用的 3 个通配符：

- `*`：匹配任何数量字符
- `..`：匹配任何数量字符的重复，如任何数量子包，任何数量方法参数
- `+`：匹配指定类型及其子类型，仅作为后缀防过载类型模式后面。

#### execution

用于匹配方法执行，最常用。
##### 格式说明

```java
   execution(modifiers-pattern? ret-type-pattern declaring-type-pattern?name-pattern(param-pattern)
                throws-pattern?)
```

- 其中带 `?`号的 `modifiers-pattern?`，`declaring-type-pattern?`，`throws-pattern?`是可选项
- `ret-type-pattern`,`name-pattern`, `parameters-pattern`是必选项
- `modifier-pattern?` 修饰符匹配，如 public 表示匹配公有方法，`*`表示任意修饰符
- `ret-type-pattern` 返回值匹配，`*` 表示任何返回值，全路径的类名等
- `declaring-type-pattern?` 类路径匹配
- `name-pattern` 方法名匹配，`*` 代表所有，`xx*`代表以 xx 开头的所有方法
- `(param-pattern)` 参数匹配，指定方法参数（声明的类型），`(..)`代表所有参数，`(*,String)`代表第一个参数为任何值，第二个为 String 类型，`(..,String)`代表最后一个参数是 String 类型
- `throws-pattern?` 异常类型匹配

##### 举例说明

```java
public class PointcutExecution {

    // com.crab.spring.aop.demo02 包下任何类的任意方法
    @Pointcut("execution(* com.crab.spring.aop.demo02.*.*(..))")
    public void m1(){}

    // com.crab.spring.aop.demo02 包及其子包下任何类的任意方法
    @Pointcut("execution(* com.crab.spring.aop.demo02..*.*(..))")
    public void m2(){}

    // com.crab.spring.aop 包及其子包下 IService 接口的任意无参方法
    @Pointcut("execution(* com.crab.spring.aop..IService.*(..))")
    public void m3(){}

    // com.crab.spring.aop 包及其子包下 IService 接口及其子类型的任意无参方法
    @Pointcut("execution(* com.crab.spring.aop..IService+.*(..))")
    public void m4(){}

    // com.crab.spring.aop.demo02.UserService 类中有且只有一个 String 参数的方法
    @Pointcut("execution(* com.crab.spring.aop.demo02.UserService.*(String))")
    public void m5(){}

    // com.crab.spring.aop.demo02.UserService 类中参数个数为 2 且最后一个参数类型是 String 的方法
    @Pointcut("execution(* com.crab.spring.aop.demo02.UserService.*(*,String))")
    public void m6(){}

    // com.crab.spring.aop.demo02.UserService 类中最后一个参数类型是 String 的方法
    @Pointcut("execution(* com.crab.spring.aop.demo02.UserService.*(..,String))")
    public void m7(){}
}
```

#### within

##### 格式说明

`within（类型表达式）`：目标对象 target 的类型是否和 within 中指定的类型匹配

> 匹配规则： target.getClass().equals(within 表达式中指定的类型）

##### 举例说明

```java
public class PointcutWithin {
    // 匹配 com.crab.spring.aop.demo02 包及其子包下任何类的任何方法
    @Pointcut("within(com.crab.spring.aop.demo02..*)")
    public void m() {
    }

    // 匹配 m.crab.spring.aop.demo02 包及其子包下 IService 类型及其子类型的任何方法
    @Pointcut("within(com.crab.spring.aop.demo02..IService+)")
    public void m2() {
    }

    // 匹配 com.crab.spring.aop.demo02.UserService 类中所有方法，不含其子类
    @Pointcut("within(com.crab.spring.aop.demo02.UserService)")
    public void m3() {
    }
}
```

#### this

##### 格式说明

`this（类型全限定名）`：通过 aop 创建的**代理对象的类型**是否和 this 中指定的类型匹配；this 中使用的表达式必须是类型全限定名，不支持通配符。

```java
this(x) 的匹配规则是：x.getClass.isAssingableFrom(proxy.getClass)
```

##### 举例说明

```java
package com.crab.spring.aop.demo02.aspectj;

@Aspect
public class PointcutThis {
    interface I1{
        void m();
    }
    static class C1 implements I1{

        @Override
        public void m() {
            System.out.println("C1 m()");
        }
    }
	// 匹配 I1 类型或是其子类
    @Pointcut("this(com.crab.spring.aop.demo02.aspectj.PointcutThis.I1)")
    public void pc(){}

    @Before("pc()")
    public void before(JoinPoint joinPoint) {
        System.out.println("before: " + joinPoint);
    }

    public static void main(String[] args) {
        C1 target = new C1();
        AspectJProxyFactory proxyFactory = new AspectJProxyFactory();
        proxyFactory.setTarget(target);
        // proxyFactory.setProxyTargetClass(true);
        // 获取 C1 上所有接口 spring 工具类提供的方法
        Class<?>[] allInterfaces = ClassUtils.getAllInterfaces(target);
        // 设置代理接口
        proxyFactory.setInterfaces(allInterfaces);
        // 添加切面
        proxyFactory.addAspect(PointcutThis.class);
        // 获取代理
        I1 proxy = proxyFactory.getProxy();
        // 调用方法
        proxy.m();
        System.out.println("JDK 代理？" + AopUtils.isJdkDynamicProxy(proxy));
        System.out.println("CGLIB 代理？" + AopUtils.isCglibProxy(proxy));
        //判断代理对象是否是 C1 类型的
        System.out.println(C1.class.isAssignableFrom(proxy.getClass()));
    }

}
```

来观察下输出

```csharp
before: execution(void com.crab.spring.aop.demo02.aspectj.PointcutThis$C1.m())
C1 m()
JDK 代理？false
CGLIB 代理？true
true
```

使用 JDK 动态代理生成的代理对象，其类型是 I1 类型。

> 思考下：将切点表达式改成下面的输出结果是？
>
> // 匹配 C1 类型或是其子类
> @Pointcut("this(com.crab.spring.aop.demo02.aspectj.PointcutThis.C1)")
> public void pc(){}

#### target

##### 格式说明

`target（类型全限定名）`：判断**目标对象的类型**是否和指定的类型匹配；表达式必须是类型全限定名，不支持通配符。

```java
target(x) 匹配规则：x.getClass().isAssignableFrom(target.getClass());
```

##### 举例说明

```java
@Aspect
public class PointcutTarget {
    interface I1{
        void m();
    }
    static class C1 implements I1{

        @Override
        public void m() {
            System.out.println("C1 m()");
        }
    }

    // 匹配目标类型必须是
    @Pointcut("target(com.crab.spring.aop.demo02.aspectj.PointcutTarget.C1)")
    public void pc(){}

    @Before("pc()")
    public void before(JoinPoint joinPoint) {
        System.out.println("before: " + joinPoint);
    }

    public static void main(String[] args) {
        C1 target = new C1();
        AspectJProxyFactory proxyFactory = new AspectJProxyFactory();
        proxyFactory.setTarget(target);
        proxyFactory.setProxyTargetClass(true);
        // 获取 C1 上所有接口 spring 工具类提供的方法
        Class<?>[] allInterfaces = ClassUtils.getAllInterfaces(target);
        // 设置代理接口
        proxyFactory.setInterfaces(allInterfaces);
        // 添加切面
        proxyFactory.addAspect(PointcutTarget.class);
        // 获取代理
        I1 proxy = proxyFactory.getProxy();
        // 调用方法
        proxy.m();
        System.out.println("JDK 代理？" + AopUtils.isJdkDynamicProxy(proxy));
        System.out.println("CGLIB 代理？" + AopUtils.isCglibProxy(proxy));
        //判断代理对象是否是 C1 类型的
        System.out.println(C1.class.isAssignableFrom(target.getClass()));
    }

}
```

输出结果

```java
before: execution(void com.crab.spring.aop.demo02.aspectj.PointcutTarget$C1.m())
C1 m()
JDK 代理？false
CGLIB 代理？true
true
```

#### args

##### 格式说明

`args（参数类型列表）`匹配**当前执行的方法传入的参数**是否为 args 中指定的类型；参数类型列表中的参数必须是**类型全限定名，不支持通配符**；**args 属于动态切入点，也就是执行方法的时候进行判断的，开销非常大，非特殊情况最好不要使用。**

```java
args(String) //    方法个数为 1，类型是 String
args(*,String) //  方法参数个数 2，第 2 个是 String 类型
args(..,String) // 方法个数不限制，最后一个必须是 String
```

##### 举例说明

```java
package com.crab.spring.aop.demo02.aspectj;

@Aspect
public class PointcutArgs {
    interface I1{
        void m(Object name);
    }
    static class C1 implements I1{

        @Override
        public void m(Object name) {
            String type = name.getClass().getName();
            System.out.println("C1 m() 参数类型 " + type);
        }
    }

    // 匹配方法参数个数 1 且类型是必须是 String
    @Pointcut("args(String)")
    public void pc(){}

    @Before("pc()")
    public void before(JoinPoint joinPoint) {
        System.out.println("before: " + joinPoint);
    }

    public static void main(String[] args) {
        C1 target = new C1();
        AspectJProxyFactory proxyFactory = new AspectJProxyFactory();
        proxyFactory.setTarget(target);
        proxyFactory.setProxyTargetClass(true);
        // 获取 C1 上所有接口 spring 工具类提供的方法
        Class<?>[] allInterfaces = ClassUtils.getAllInterfaces(target);
        // 设置代理接口
        proxyFactory.setInterfaces(allInterfaces);
        // 添加切面
        proxyFactory.addAspect(PointcutArgs.class);
        // 获取代理
        I1 proxy = proxyFactory.getProxy();
        // 调用方法
        proxy.m("xxxx");
        proxy.m(100L);
        System.out.println("JDK 代理？" + AopUtils.isJdkDynamicProxy(proxy));
        System.out.println("CGLIB 代理？" + AopUtils.isCglibProxy(proxy));
        //判断代理对象是否是 C1 类型的
        System.out.println(C1.class.isAssignableFrom(target.getClass()));
    }

}
```

观察下输出

```java
before: execution(void com.crab.spring.aop.demo02.aspectj.PointcutArgs$C1.m(Object))
C1 m() 参数类型 java.lang.String
C1 m() 参数类型 java.lang.Long
JDK 代理？false
CGLIB 代理？true
true	
```

参数类型传递是 String 时候增强了，而 Long 的时候没有执行增强方法。

#### @within

##### 格式说明

`@within（注解类型）`：匹配指定的注解内定义的方法。

```java
匹配规则： 被调用的目标方法 Method 对象。getDeclaringClass().getAnnotation(within 中指定的注解类型） != null
```

##### 举例说明

```java
package com.crab.spring.aop.demo02.aspectj;

@Aspect
public class PointcutAnnWithin {
    @Retention(RetentionPolicy.RUNTIME)
    @Target(ElementType.TYPE)
    @interface MyAnn {
    }

    interface I1 {
        void m();
    }

    @MyAnn
    static class C1 implements I1 {
        @Override
        public void m() {
            System.out.println("C1 m()");
        }
    }

    // 匹配目标类型必须上必须有注解 MyAnn
    @Pointcut("@within(com.crab.spring.aop.demo02.aspectj.PointcutAnnWithin.MyAnn)")
    public void pc() {
    }

    @Before("pc()")
    public void before(JoinPoint joinPoint) {
        System.out.println("before: " + joinPoint);
    }

    public static void main(String[] args) {
        C1 target = new C1();
        AspectJProxyFactory proxyFactory = new AspectJProxyFactory();
        proxyFactory.setTarget(target);
        proxyFactory.setProxyTargetClass(true);
        // 获取 C1 上所有接口 spring 工具类提供的方法
        Class<?>[] allInterfaces = ClassUtils.getAllInterfaces(target);
        // 设置代理接口
        proxyFactory.setInterfaces(allInterfaces);
        // 添加切面
        proxyFactory.addAspect(PointcutAnnWithin.class);
        // 获取代理
        I1 proxy = proxyFactory.getProxy();
        // 调用方法
        proxy.m();
        System.out.println("JDK 代理？" + AopUtils.isJdkDynamicProxy(proxy));
        System.out.println("CGLIB 代理？" + AopUtils.isCglibProxy(proxy));
        //判断代理对象是否是 C1 类型的
        System.out.println(C1.class.isAssignableFrom(target.getClass()));
    }

}
```

输出

```java
before: execution(void com.crab.spring.aop.demo02.aspectj.PointcutAnnWithin$C1.m())
C1 m()
JDK 代理？false
CGLIB 代理？true
true
```

> 思考下父类上有注解，子类继承父类的方法，同时考虑下注解@Inherited 是否在切点注解的场景？

#### @target

##### 格式说明

`@target（注解类型）`：判断目标对象 target 类型上是否有指定的注解；@target 中注解类型也必须是全限定类型名。

```java
匹配规则： target.class.getAnnotation（指定的注解类型） != null
```

注意，如果目标注解是标注在父类上的，那么定义目标注解时候应使用`@Inherited`标注，使子类能继承父类的注解。

##### 举例说明

```java
package com.crab.spring.aop.demo02.aspectj;

@Aspect
public class PointcutAnnTarget {
    @Retention(RetentionPolicy.RUNTIME)
    @Target(ElementType.TYPE)
    @Inherited // 子类能继承父类的注解
    @interface MyAnn2 {
    }

    @MyAnn2 // 注解在父类上
    static class P1 {
        void m(){}
    }

    static class C1 extends P1 {
        @Override
        public void m() {
            System.out.println("C1 m()");
        }
    }

    // 匹配目标类型必须上必须有注解 MyAnn
    @Pointcut("@target(com.crab.spring.aop.demo02.aspectj.PointcutAnnTarget.MyAnn2)")
    public void pc() {
    }

    @Before("pc()")
    public void before(JoinPoint joinPoint) {
        System.out.println("before: " + joinPoint);
    }

    public static void main(String[] args) {
        C1 target = new C1();
        AspectJProxyFactory proxyFactory = new AspectJProxyFactory();
        proxyFactory.setTarget(target);
        proxyFactory.setProxyTargetClass(true);
        // 获取 C1 上所有接口 spring 工具类提供的方法
        Class<?>[] allInterfaces = ClassUtils.getAllInterfaces(target);
        // 设置代理接口
        proxyFactory.setInterfaces(allInterfaces);
        // 添加切面
        proxyFactory.addAspect(PointcutAnnTarget.class);
        // 获取代理
        C1 proxy = proxyFactory.getProxy();
        // 调用方法
        proxy.m();
        System.out.println("JDK 代理？" + AopUtils.isJdkDynamicProxy(proxy));
        System.out.println("CGLIB 代理？" + AopUtils.isCglibProxy(proxy));
        // 目标类上是否有切点注解
        System.out.println(target.getClass().getAnnotation(MyAnn2.class)!= null);
    }

}
```

输出结果

```java
before: execution(void com.crab.spring.aop.demo02.aspectj.PointcutAnnTarget$C1.m())
C1 m()
JDK 代理？false
CGLIB 代理？true
true
```

从结果最后一行看，目标对象继承了父类的注解，符合@target 的切点规则。

#### @args

##### 格式说明

`@args（注解类型）`：方法参数所属的类上有指定的注解；注意不是参数上有指定的注解，而是参数类型的类上有指定的注解。和`args`类似，不过针对的是参数类型上的注解。

```java
匹配规则： 传入的目标位置参数。getClass().getAnnotation(@args（对应的参数位置的注解类型）)!= null
```

##### 举例说明

```java
package com.crab.spring.aop.demo02.aspectj;

@Aspect
public class PointcutAnnArgs {
    @Retention(RetentionPolicy.RUNTIME)
    @Target(ElementType.TYPE)
    @Inherited // 子类能继承父类的注解
    @interface MyAnn3 {
    }

    @MyAnn3
    static class MyParameter{

    }

    static class C1  {
        public void m(MyParameter myParameter) {
            System.out.println(myParameter.getClass().getAnnotation(MyAnn3.class));
            System.out.println("C1 m()");
        }
    }

    // 匹配方法上最后的一个参数类型上有注解 MyAnn3
    @Pointcut("@args(..,com.crab.spring.aop.demo02.aspectj.PointcutAnnArgs.MyAnn3)")
    public void pc() {
    }

    @Before("pc()")
    public void before(JoinPoint joinPoint) {
        System.out.println("before: " + joinPoint);
    }

    public static void main(String[] args) {
        C1 target = new C1();
        AspectJProxyFactory proxyFactory = new AspectJProxyFactory();
        proxyFactory.setTarget(target);
        proxyFactory.setProxyTargetClass(true);
        // 获取 C1 上所有接口 spring 工具类提供的方法
        Class<?>[] allInterfaces = ClassUtils.getAllInterfaces(target);
        // 设置代理接口
        proxyFactory.setInterfaces(allInterfaces);
        // 添加切面
        proxyFactory.addAspect(PointcutAnnArgs.class);
        // 获取代理
        C1 proxy = proxyFactory.getProxy();
        // 调用方法
        MyParameter myParameter = new MyParameter();
        proxy.m(myParameter);
        System.out.println("JDK 代理？" + AopUtils.isJdkDynamicProxy(proxy));
        System.out.println("CGLIB 代理？" + AopUtils.isCglibProxy(proxy));
        // 目标类上是否有切点注解
        System.out.println(myParameter.getClass().getAnnotation(MyAnn3.class)!= null);
    }

}
```

观察结果

```java
before: execution(void com.crab.spring.aop.demo02.aspectj.PointcutAnnArgs$C1.m(MyParameter))
@com.crab.spring.aop.demo02.aspectj.PointcutAnnArgs$MyAnn3()
C1 m()
JDK 代理？false
CGLIB 代理？true
true
```

第二行中目标方法上输出了参数的注解。

最后一行判断参数类型上确实有注解。

#### @annotation

##### 格式说明

`@annotation（注解类型）`：匹配被调用的目标对象的方法上有指定的注解

```java
匹配规则：target.getClass().getMethod("目标方法名").getDeclaredAnnotation(@annotation（目标注解）)!=null
```

这个在针对特定注解的方法日志拦截场景下应用比较多。

##### 举例说明

```java
package com.crab.spring.aop.demo02.aspectj;

@Aspect
public class PointcutAnnotation {
    @Retention(RetentionPolicy.RUNTIME)
    @Target(ElementType.METHOD)
    @interface MyAnn4 {
    }

    /**
     * 父类 方法上都有@MyAnn4
     */
    static class P1{
        @MyAnn4
        public void m1(){
            System.out.println("P1 m()");
        }
        @MyAnn4
        public void m2(){
            System.out.println("P1 m2()");
        }
    }

    /**
     * 子类
     * 注意重新重写了父类的 m1 方法但是没有声明注解@Ann4
     * 新增了 m3 方法带注解@Ann4
     */
    static class C1 extends P1 {
        @Override
        public void m1() {
            System.out.println("C1 m1()");
        }

        @MyAnn4
        public void m3() {
            System.out.println("C1 m3()");
        }
    }

    // 匹配调用的方法上必须有注解
    @Pointcut("@annotation(com.crab.spring.aop.demo02.aspectj.PointcutAnnotation.MyAnn4)")
    public void pc() {
    }

    @Before("pc()")
    public void before(JoinPoint joinPoint) {
        System.out.println("before: " + joinPoint);
    }

    public static void main(String[] args) throws NoSuchMethodException {
        C1 target = new C1();
        AspectJProxyFactory proxyFactory = new AspectJProxyFactory();
        proxyFactory.setTarget(target);
        proxyFactory.setProxyTargetClass(true);
        // 获取 C1 上所有接口 spring 工具类提供的方法
        Class<?>[] allInterfaces = ClassUtils.getAllInterfaces(target);
        // 设置代理接口
        proxyFactory.setInterfaces(allInterfaces);
        // 添加切面
        proxyFactory.addAspect(PointcutAnnotation.class);
        // 获取代理
        C1 proxy = proxyFactory.getProxy();
        // 调用方法
        proxy.m1();
        proxy.m2();
        proxy.m3();

        System.out.println("JDK 代理？" + AopUtils.isJdkDynamicProxy(proxy));
        System.out.println("CGLIB 代理？" + AopUtils.isCglibProxy(proxy));

        // 目标对象的目标方法上是否直接声明了注解 MyAnn4
        System.out.println(target.getClass().getMethod("m1").getDeclaredAnnotation(MyAnn4.class)!=null);
        System.out.println(target.getClass().getMethod("m2").getDeclaredAnnotation(MyAnn4.class)!=null);
        System.out.println(target.getClass().getMethod("m3").getDeclaredAnnotation(MyAnn4.class)!=null);
    }

}
```

观察下结果

```java
C1 m1()
before: execution(void com.crab.spring.aop.demo02.aspectj.PointcutAnnotation$P1.m2())
P1 m2()
before: execution(void com.crab.spring.aop.demo02.aspectj.PointcutAnnotation$C1.m3())
C1 m3()
JDK 代理？false
CGLIB 代理？true
false
true
```

简单分析下：
1. C1 中重写了 m1 方法，上面有没有 @Ann4，所有方法没有被拦截
2. 其它的 m2 在父类上有注解@Ann4，m3 在子类上也有注解@Ann4，所以拦截了。
3. 最后 3 行输出了目标对象的 3 个方法上是否有注解的情况。

#### bean

##### 格式说明

**bean(bean 名称）**：这个用在 spring 环境中，匹配容器中指定名称的 bean。

```java
匹配格式：ApplicationContext.getBean("bean 表达式中指定的 bean 名称") != null
```

##### 举例说明

定义一个 bean

```java
package com.crab.spring.aop.demo02.aspectj;

public class MyBean {
    private String beanName;

    public MyBean(String beanName) {
        this.beanName = beanName;
    }

    public void m() {
        System.out.println("我是" + this.beanName);
    }
}
```

切面中的切点和通知定义

```java
@Aspect
public class PointcutBean {
    // 容器中 bean 名称是"myBean1"的方法进行拦截
    @Pointcut("bean(myBean1)")
    public void pc() {
    }

    @Before("pc()")
    public void m(JoinPoint joinPoint) {
        System.out.println("start " + joinPoint);
    }
}
```

组合使用

```java
@Aspect
@Configuration
@EnableAspectJAutoProxy // 自动生成代理对象
public class PointcutBeanConfig {

    // 注入 myBean1
    @Bean("myBean1")
    public MyBean myBean1() {
        return new MyBean("myBean1");
    }

    //  myBean2
    @Bean("myBean2")
    public MyBean myBean2() {
        return new MyBean("myBean2");
    }

    // 注入切面
    @Bean("pointcutBean")
    public PointcutBean pointcutBean() {
        return new PointcutBean();
    }

    public static void main(String[] args) {
        AnnotationConfigApplicationContext context =
                new AnnotationConfigApplicationContext(PointcutBeanConfig.class);
        MyBean myBean1 = context.getBean("myBean1", MyBean.class);
        myBean1.m();
        MyBean myBean2 = context.getBean("myBean2", MyBean.class);
        myBean2.m();
    }

}
```

观察下结果

```java
start execution(void com.crab.spring.aop.demo02.aspectj.MyBean.m())
我是 myBean1
我是 myBean2
```

myBean1 的方法被拦截了。

上面介绍了 Spring 中 10 中切点表达式，下面介绍下切点的组合使用和公共切点的抽取。

### 切点的组合

切点与切点直接支持逻辑逻辑组合操作： `&&` 、`||、` `!`。使用较小的命名组件构建更复杂的切入点表达式是最佳实践。

##### 同一个类内切点组合

```java
public class CombiningPointcut {

    /**
     * 匹配 com.crab.spring.aop.demo02 包及子包下任何类的 public 方法
     */
    @Pointcut("execution(public * com.crab.spring.aop.demo02..*.*(..))")
    public void publicMethodPc() {
    }

    /**
     * com.crab.spring.aop.demo02.UserService 类的所有方法
     */
    @Pointcut("execution(* com.crab.spring.aop.demo02.UserService.*(..))")
    public void serviceMethodPc(){}

    /**
     * 组合的切点
     */
    @Pointcut("publicMethodPc() && serviceMethodPc()")
    public void combiningPc(){

    }
    /**
     * 组合的切点 2
     */
    @Pointcut("publicMethodPc() || !serviceMethodPc()")
    public void combiningPc2(){

    }

}
```

##### 不同类之间切点组合

切点方法的可见性会影响组合但是不影响切点的匹配。

```java
public class CombiningPointcut2 {

    /**
     * com.crab.spring.aop.demo02.UserService 类的所有方法
     */
    @Pointcut("execution(* com.crab.spring.aop.demo02.UserService.*(..))")
    public void serviceMethodPc2(){}

    /**
     * 组合的切点，跨类组合
     */
    @Pointcut("com.crab.spring.aop.demo02.aspectj.reuse.CombiningPointcut.publicMethodPc() && serviceMethodPc2()")
    public void combiningPc(){

    }
    /**
     * 组合的切点，跨类组合，由于 serviceMethodPc 是 private, 此处无法组合
     */
    @Pointcut("com.crab.spring.aop.demo02.aspectj.reuse.CombiningPointcut.serviceMethodPc() && serviceMethodPc2()")
    public void combiningPc2(){

    }
}
```

### 切点的公用

在使用企业应用程序时，开发人员通常希望从多个方面引用应用程序的模块和特定的操作集。建议为此目的定义一个捕获公共切入点表达式的 CommonPointcuts 方面。直接看案例。

不同层的公共切点

```java
/**
 * 公用的切点
 */
public class CommonPointcuts {

    /**
     * web 层的通用切点
     */
    @Pointcut("within(com.xyz.myapp.web..*)")
    public void inWebLayer() {}

    @Pointcut("within(com.xyz.myapp.service..*)")
    public void inServiceLayer() {}

    @Pointcut("within(com.xyz.myapp.dao..*)")
    public void inDataAccessLayer() {}

    @Pointcut("execution(* com.xyz.myapp..service.*.*(..))")
    public void businessService() {}

    @Pointcut("execution(* com.xyz.myapp.dao.*.*(..))")
    public void dataAccessOperation() {}
}
```

程序中可以直接引用这些公共的切点

```java

@Aspect
public class UseCommonPointcuts {

    /**
     * 直接使用公共切点
     */
    @Before("com.crab.spring.aop.demo02.aspectj.reuse.CommonPointcuts.inWebLayer()")
    public void before(JoinPoint joinPoint){
        System.out.println("before:" + joinPoint);
    }
}
```


### 带参数的切点

```java
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(classes = AspectConfig.class)
public class AspectDemo {
    @Autowired
    private List<Perform> performList;

    @Test
    public void testPerform(){
        for (Perform perform : performList) {
            perform.doPerform("dc1");
        }
    }
}


@Configuration
@ComponentScan
@EnableAspectJAutoProxy
public class AspectConfig {
    @Bean
    public Audience audience() {
        return new Audience();
    }
}

@Aspect
public class Audience {

    /**
     * 声明一个切点
     */
    @Pointcut("execution(* io2.dc.Perform.doPerform(..)) && bean(poet)")
    public void perform(){};


    /**
     * 声明一个可以接收参数的切点
     * @param name
     */
    @Pointcut("execution(* io2.dc.Perform.doPerform(String)) && args(name)")
    public void performWithArg(String name){};

    @Before("perform()")
    public void drinkWater() {
        System.out.println("喝口水");
    }



    @Before("performWithArg(name)")
    public void printName(String name) {
        System.out.println((name + "开始表演了"));
    }
}

public interface Perform{
    int doPerform(String name);
}

@Component
public class Poet implements Perform {

    @Override
    public int doPerform(String name) {
        System.out.println(("朗诵" + name));
        return 0;
    }
}

@Component
public class Singer implements Perform {

    @Override
    public int doPerform(String name) {
        System.out.println(("歌唱家" + name));
        return 0;
    }
}

```

参考资料
- https://www.cnblogs.com/kongbubihai/p/16017046.html
- 《Spring 实战第4版》