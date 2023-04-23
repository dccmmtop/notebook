---
title: java中包的扫描
date: 2023-04-23 21:16:48
tags: [java]
---

用过spring框架后知道包扫描是一个非常好用的功能，只需要在某个包下写自己的类，框架就能自动帮我们加载到容器中，从而在各处使用，今天自己来实现一下包扫描。

原理其实很简单，就是找到某个目录下的所有class文件，然后使用类加载器加载到jvm中，再使用反射生成一个该类的对象即可。


### 需求

实现一个文件监控的服务，当文件或者目录发生变化时，根据不同的文件做不同的处理。要监控的目录要支持从配置文件中读取

### 思路

首先想到的是
1. 监控目录，得知文件的变动信息
2. 根据文件名字判断需要做什么处理

很容易写出面的伪代码:

```java
// 当文件发生变化时
public dealOnChange(String filePath){
    if(filePath.equal("aa")){
        // todo
    }else if(filepath.equal("bb")){
        // todo
    }
}
```

上面代码确实很容易实现，但是扩展能力不强。当某天需要新增一个监控文件，就需要**修改 `dealOnChange`** 方法，增加一个分支判断，当修改了代码就有可能引入bug，不满足 OCP 原则。

> OCP要求软件实体应该是可扩展的，但不应该修改。这意味着，如果需要更改行为，应该使用继承或组合来实现，而不是修改现有代码。它还要求代码应该是可重用的，而不是重新编写。这样，你就可以利用现有的代码，而不是重写它。


可以定义一个文件变动处理器接口，不同的文件变动时，使用不同处理器的实现类,伪代码如下:
```java
interface FileChangeListener {
    void deal(String filePath);
    void select(String filePath);
}


// 当文件发生变化时
class Main {
    List<FileChangeListener> fileChangeListenerList;

    public dealOnChange(String filePath){
       FileChangeListener  listener;
       for( FileChangeListener f : fileChangeListenerList) {
            if(f.select(filePath)) {
                    listener = f;
                    break
            }
       }
       // if listener  is null ,do other...
       listener.deal(filePath)
    }
    
    public static void main(String[] args) {
        // todo: 把所有实现了 FileChangeListener 接口的类都的对象都添加到 fileChangeListenerList 集合中
        // fileChangeListenerList = loadAllListenerClass()
        while(true) {
            // 假设getChange 可以获取到变化的文件路径
            String filePath = getChange();
            dealOnChange(filePath)
        }
    }
}
```

上面的伪代码可以实现这样的功能： 当需要增加一个监控文件时，只需新写一个类，然后实现 FileChangeListener 接口，在这个类中处理文件变化时需要做的动作。这样与第一版的区别是：**增加功能时，不修改旧代码，而是新增代码**

现在关键的问题来了，怎么实现 `loadAllListenerClass()`:

### 加载指定目录下的class

因为一堆 class 文件可以打包成 jar包， 然后使用 `java -jar` 的方式运行。也可以不用打包，直接运行 `java Main`。 不同的运行方式导致从目录中找文件的方式也不一样。分别如下:

#### 直接从目录中加载
```java
public  List<Class<?>> getClassListFromDir(String packagePath) {
    // 先获取包的路径
    String localPath = this.getClass().getClassLoader().getResource(packagePath.replace(".","/")).getPath();
    File classFile = new File(localPath );
    List<Class<?>> klassList = new ArrayList<>();
    // 遍历这个目录下的所有文件(假设都是class文件)
    for (File file : Objects.requireNonNull(classFile.listFiles())) {
        try {
            // 拼接 class 文件的全限定名,并加载
            Class<?> klass = Class.forName(packagePath + "." + file.getName().replace(".class","") );
            Logger.info("加载配置处理器: " + klass.getName());
            // 如果是接口，跳过
            if(klass.isInterface()){
                continue;
            }
            // 将类对象添加到集合中
            klassList.add(klass);
        } catch (ClassNotFoundException e) {
            Logger.info("加载类失败: "+ e.getMessage());
        }
    }
    return klassList;
}
```

#### 从 jar 中加载

```java

/**
    * 扫描 jar包中的文件获取class
    * 需要特殊的工具读取jar包中内容，不能向读取目录一样
    * @param packagePath 要扫描的包路径
    * @return 类对象
    */
public static List<Class<?>> getClassListFromJarFile(String packagePath) {
    // 得到 jar 包的位置
    String jarPath = Config.class.getProtectionDomain().getCodeSource().getLocation().getPath();
    List<Class<?>> klassList = new ArrayList<>();

    JarFile jarFile = null;
    try {
        jarFile = new JarFile(jarPath);
    } catch (IOException e) {
        Logger.info(e.getMessage());
    }

    List<JarEntry> jarEntryList = new ArrayList<JarEntry>();

    Enumeration<JarEntry> ee = jarFile.entries();
    packagePath = packagePath.replace(".","/");
    while (ee.hasMoreElements()) {
        JarEntry entry = ee.nextElement();
        // 过滤我们出满足我们需求的东西
        if (entry.getName().startsWith(packagePath) && entry.getName().endsWith(".class")) {
            jarEntryList.add(entry);
        }
    }
    for (JarEntry entry : jarEntryList) {
        String className = entry.getName().replace('/', '.');
        className = className.substring(0, className.length() - 6);
        // 也可以采用如下方式把类加载成一个输入流
        // InputStream in = jarFile.getInputStream(entry);
        try {

            Logger.info("加载配置处理器: " + className);
            Class<?> klass = Thread.currentThread().getContextClassLoader().loadClass(className);
            if(klass.isInterface()){
                continue;
            }
            klassList.add(klass);
        } catch (ClassNotFoundException e) {
            Logger.info("加载类失败: " + e.getMessage());
        }
    }

    return klassList;
}
```

到此关键的代码已经完成。拿到类对象后，就可以使用反射 `klass.newInstance()` 生成实例了。

本文中的示例的完整可运行代码已开源: [欢迎star](https://github.com/dccmmtop/SyncConfig)