---
title: IoC 思想和实现
date: 2022-11-04 15:49:47
tags: [java]
---

我们先不粘贴官方的晦涩定义，通过一个例子来一步一步的引出 IoC 思想，真正的体会到 IoC 思想对我们编程带来的益处。

## 车，引擎，轮胎

一个汽车需要引擎和轮胎，有下面模型：
```java
/**
 * 东风汽车
 */
class NissanCar{
    private Engine engine;
    private Tyre tyre;

    public NissanCar() {
        this.engine = new EngineV1();
        this.tyre = new TyreV1();
    }
}

/**
 * 大众汽车
 */
class VolkswagenCar{
    private Engine engine;
    private Tyre tyre;

    public VolkswagenCar() {
        this.engine = new EngineV1();
        this.tyre = new TyreV1();
    }
}

// .... 还有几十种其他品牌的车。用的都是 V1 引擎

/**
 * 引擎接口，输出动力
 */
interface Engine {
    void outputPower();
}

class EngineV1 implements Engine {

    public void outputPower() {
    }
}

/**
 * 轮胎接口，可以转动
 */
interface Tyre {
    void turn();
}
class TyreV1 implements Tyre {

    public void turn() {

    }
}

```

无论什么汽车都需要引擎和轮胎，我们构造一个汽车时，必须同时构造一个引擎和轮胎的对象，这样的汽车才能正常工作，这也是我们正常的编码方式，一切都很美好。直到有一天，发生了一起严重的交通事故，某人正在开着汽车，突然加速，无法控制。直到撞上了其他汽车才停下来，同时也受了非常严重的伤。汽车厂商的工程师排查很久发现是引擎出了问题，在某些情况下，会突然不受控制，以最大马力转动。

生产引擎的厂商很快修复了这个问题，并推出了 v2 版本的引擎。只要所有的车都换了最新的引擎就彻底解决了这个问题。.. 这个现象对应到我们上面的模型，就是：

```java
class EngineV2 implements Engine {

    public void outputPower() {
    }
}
```
然后所有汽车的构造方法中，都要修改成：`this.engine = new EngineV2()`。 看起来也不是什么大问题，我们借助编辑器，来个全局替换不就行了。

等等，别忘了我们编写的这程序只是一个示例，非常非常简单，实际应用中我们不可能有这么简单的应用，这么清晰明了的依赖关系，我们应用中的用户依赖汽车，汽车依赖引擎，依赖轮胎，依赖座椅，依赖变速系统，刹车系统，而变速系统可能会和引擎有交互，刹车系统也可能和引擎有交互等等，非常复杂的依赖关系。可不敢全局替换后直接提交到生产运行。我们必须要做详尽的测试，

我们的程序不可能是写完后就一层不变的，我们的程序就是为了解决现实生活中的问题，而现实生活最不缺的就是变化，如果需求变化，我们的程序都要发生如此之大的改动，对程序员来说简直是秃顶之灾。必须寻求解决之道。

## 工厂方法

灾难发生的原因就在与底层的引擎发生了变化，而引擎被众多汽车依赖，汽车也就必须发生变化，如果众汽车厂商在生产汽车的时候，不要主动的去创建某种类型的引擎，而是告诉引擎工厂：给我一个引擎。如果以后在需要更换引擎的时候，众多汽车厂商不再做什么改动，仍是告诉引擎工厂：给我一个引擎，引擎工厂自会把合适引擎返回给汽车厂商，如下：
```java
/**
 * 东风汽车
 */
class NissanCar{
    private Engine engine;
    private Tyre tyre;

    public NissanCar() {
        this.engine = EngineFactory.get();
        this.tyre = TyreFactory.get();
    }
}

/**
 * 大众汽车
 */
class VolkswagenCar{
    private Engine engine;
    private Tyre tyre;

    public VolkswagenCar() {
        this.engine = EngineFactory.get();
        this.tyre = TyreFactory.get();
    }
}

// .... 还有几十种其他品牌的车。用的都是 V1 引擎

/**
 * 引擎工厂
 */
class EngineFactory {
    public static Engine get(){
        return new EngineV2();
    }
}

/** 
 * 轮胎工厂
 */
class TyreFactory {
    public static Tyre get(){
        return new TyreV1();
    }
}
```

从原来汽车厂商自己构造引擎，然后组装到车上（赋值动作）, 简化到直接组装引擎即可，不再关注引擎如何制造了。再升级引擎时，那就是引擎工厂的事了，和汽车厂商无关，而引擎工厂只有一个，升级的工作量也比较少。代码改动少，那么对整体系统的影响就比较小。世界又再次美好了。 但是刚刚说过，这只是一个简单的示例程序，依赖关系比较清晰，真实世界中，一辆车不可能只有引擎，轮胎，还会有座椅，方向盘，灯，刹车，变速箱等等。可能会觉得，那就继续添加工厂呗，给每个零件都添加一个工厂方法。组装汽车需要的零件都从工厂方法中获取，不要自己 new 对象出来。嗯，这样当然可以，但是一辆车至少需要上百上千个零件，我们都要自己去建工厂方法，然后组装吗？这样太累了。

我们再看一下构造汽车都做了哪些工作？
1. 声明需要的配件（定义属性： 如：private Engine engine)
2. 获取配件（在构造方法中调用配件的工厂方法，如： EngineFactory.get())
3. 组装配件（在构造方法中赋值，如 this.engine = EngineFactory.get())

不管是汽车厂商自己构造配件，还是通过工厂方法构造，都是我们自己 new 出来的配件对象（步骤 2)，然后由自己把配件对象赋值给汽车，解决汽车与配件的依赖关系（步骤 3), 我们再深入思考一下，可以不可以制作一个智能的汽车生产车间，我们把定义好的汽车模型和所有配件模型告诉这个生产车间（步骤 1)， 然后生产车间会根据已经定义好的配件模型和汽车模型自己生产配件（步骤 2)，把配件组装到汽车中（步骤 3)。

其实这是完全可以的，程序员已经把所有的类定义好了，类中所依赖其他对象也是明确的，像自动 new 对象以及为对象属性赋值这种机械动作就可以由某个程序自动化执行。下面我们看下如何制造这种“车间”


## 车间

1. 首先生成一个引擎对象，轮胎对象放入一个池中。
2. 解析汽车需要的所有配件
3. 去池中查找配件，把找到的配件赋值为汽车对应的属性,构造出一辆新汽车
4. 把构造好的汽车对象放入池中

这里做了一些简化：
1. 车间知道要先构建引擎对象,轮胎对象，然后再构建汽车对象
2. 引擎不依赖其他配件

如果引擎依赖另外的A配件，而A配件又依赖另外的B配件。我们是不是要先构建B配件，然后再构建A配件，再构建引擎。按照这个固定顺序才可以正常工作。如果真是这样，那么这个车间太脆弱了，太死板了。可以让车间智能一点，在构建汽车对象时，发现汽车依赖引擎，就先让汽车等一等，先把引擎构建出来，在构建引擎时，发现引擎依赖A配件，就让引擎等一等，先去构建A配件。每构造出一个完整的配件，就把这个配件放入池中，下次需要时直接使用。

上述步骤对应到代码中，我们就需要获取类中有哪些字段，字段的类型是什么，这些都需要靠反射实现，如下完整示例:

```java
/**
 * 东风汽车
 */
class NissanCar{
    private Engine engine;
    private Tyre tyre;

    void run(){
        this.engine.outputPower();
        this.tyre.turn();
        System.out.println("东风汽车开跑");
    }
}

/**
 * 大众汽车
 */
class VolkswagenCar{
    private Engine engine;
    private Tyre tyre;

    void run(){
        this.engine.outputPower();
        this.tyre.turn();
        System.out.println("大众汽车开跑");
    }

}


// .... 还有几十种其他品牌的车。用的都是 V1 引擎

class EngineFactory {
    public static Engine get(){
        return new EngineV2();
    }
}

class TyreFactory {
    public static Tyre get(){
        return new TyreV1();
    }
}

/**
 * 引擎接口，输出动力
 */
interface Engine {
    void outputPower();
}

class EngineV1 implements Engine {

    @Override
    public void outputPower() {
        System.out.println("我是 Engine1");
    }
}

class EngineV2 implements Engine {

    @Override
    public void outputPower() {
        System.out.println("我是 Engine2");
    }
}

/**
 * 轮胎接口,可以转动j
 */
interface Tyre {
    void turn();
}
class TyreV1 implements Tyre {

    @Override
    public void turn() {
        System.out.println("我是 Tyre1");
    }
}
/**
 * Author: dc
 * Date: 2022/11/4 16:03
 **/
public class IocDemo {

    /**
     * 存放实例化的对象，key 类类名，value 是对象
     */
    public static Map<String,Object> objectPool = new HashMap<>();

    public static void buildObjectPool() throws InstantiationException, IllegalAccessException {
        // 将待实例化的类添加到集合中
        // 这一步可以写一个自定义注解实现，把所有需要自动化实例的类上面添加我们自定义注解, 然后扫描所有类，把包含这个注解的类添加到集合中
        List<Class<?>> classList = new ArrayList<>();
        classList.add(NissanCar.class);
        classList.add(VolkswagenCar.class);
        classList.add(EngineV1.class);
        classList.add(EngineV2.class);
        classList.add(TyreV1.class);

        // 所有类是否都已经实例化
        boolean okFlag = false;

        // 遍历所有待实例化的集合，逐一实例化
        // 并不能一次循环就可以全部实例化完毕，假如A依赖B, 但是B还没有实例化，所以A暂时也不能实例化，等下一次循环，B 实例化后，再实例化A
        // 如果 A 依赖B, B 依赖A, 那么在这个循环永远不能结束。产生了循环依赖，这里仅做示例。不考虑循环依赖
        while(!okFlag){
            okFlag = true;
            for (Class<?> klass : classList) {
                // 如果还没有被实例化
                if(!objectPool.containsKey(klass.getName())){
                    // 利用反射，实例化该类。 如果klass有其他未实例化的依赖，o 等于 null
                    Object o = getInstance(klass);
                    if(o != null){
                        // 类名作为 key
                        objectPool.put(klass.getSimpleName(), o);
                        // 如果该类实现了一些接口，那么接口对应的实例也是该类的实例
                        for (Class<?> klassInterface : klass.getInterfaces()) {
                            objectPool.put(klassInterface.getSimpleName(), o);
                        }
                    }else{
                        // 还存在没有实例化的类，不能结束
                        okFlag  = false;
                    }
                }
            }
        }

    }

    private static Object getInstance(Class<?> klass) throws IllegalAccessException, InstantiationException {
        // new 一个空对象
        Object o =  klass.newInstance();
        String beanName = "";
        // 为对象中的所有字段赋值
        for (Field field : klass.getDeclaredFields()) {
            // 获取字段的类型
            beanName = field.getType().getSimpleName();
            // 所依赖的字段的实例暂时在对象池中找不到,暂不实例化
            if(!objectPool.containsKey(beanName)){
                return null;
            }
            // 设置私有变量可以访问
            field.setAccessible(true);
            // 从对象池中获取该字段的实例
            Object value = objectPool.get(beanName);
            // 为字段赋值
            field.set(o,value);
        }
        return o;
    }

    public static void main(String[] args) throws InstantiationException, IllegalAccessException {

        buildObjectPool();

        /**
         * 通过类型向容器中取对象，对象中的所有依赖已经自动处理完毕。
         */
        NissanCar nissanCar = (NissanCar)objectPool.get("NissanCar");
        nissanCar.run();

        VolkswagenCar volkswagenCar = (VolkswagenCar) objectPool.get("VolkswagenCar");
        volkswagenCar.run();
    }
}

```

**结果:**
```txt
我是 Engine2
我是 Tyre1
东风汽车开跑
我是 Engine2
我是 Tyre1
大众汽车开跑
```

在 main方法中，以及各种car类中，都没有使用new关键词构建对象，而是靠反射技术，自动解析各类之间的依赖关系，赋值。从而把一个个完整对象放入对象池。

上面的代码只是简单的示例，很多问题没有解决，如 循环依赖问题，实例冲突问题(一个接口多个实现类的)。虽然比较简陋，但是也足以展现自动化配置的思路了。

## 再谈IoC

1. 在最开始，直接在汽车的构造方法中 new 出来所有依赖的配件，这是汽车主动构建配件，如果某个配件发生变化，所有汽车都在做出改变。

2. 后来把汽车主动构建配件步骤交给一个个的配件工厂，如果某个配件发生变化，直接改动对应的工厂就行了。

上面这两种方法都会随着配件的增加，导致模板代码越来越多。如果有上千个配件，对于1：要在构造方法中一个个构造出配件，然后赋值给汽车对应的字段。对于2: 虽然把配件的构造步骤转移到工厂方法中，避免了大批量改动代码的问题，但是我们要写很多个工厂方法，工厂方法内容都差不多。 如果我们再开发其他系统，汽车系统中所有工厂方法都不能复用。

3. 最后我们制造了一个智能车间(buildObjectPool)，只需把所有汽车，配件的类告诉这个车间，车间就会自动维护他们的依赖关系，创建好各个对象放入池中(objectPool)，等待我们使用。同时这个车间没有任何类型信息，我们可以把它不加改动的用于任何系统。

把1、2 和 3 进行比较，发现最大的不同在于：**对象的依赖关系本来由对象自己解决变成了由外部工具解决**

这就是 IoC 的**思想**, 上面我们写的 buildObjectPool 工具，就是 IoC 思想的简单实现， 更出名的一个IoC思想的技术实现是——依赖注入(DI) 

切记 IoC 不是技术， 它是一种思想，一个重要的面向对象编程的法则，它能指导我们如何设计出松耦合、更优良的程序。传统应用程序都是由我们在类内部主动创建依赖对象，从而导致类与类之间高耦合，难于测试；有了IoC容器后，把创建和查找依赖对象的控制权交给了容器，由容器进行注入组合对象，所以对象与对象之间是松散耦合，这样也方便测试，利于功能复用，更重要的是使得程序的整个体系结构变得非常灵活。

其实IoC对编程带来的最大改变不是从代码上，而是从思想上，发生了“主从换位”的变化。应用程序原本是老大，要获取什么资源都是主动出击，但是在IoC/DI思想中，应用程序就变成被动的了，被动的等待IoC容器来创建并注入它所需要的资源了。

IoC很好的体现了面向对象设计法则之一—— 好莱坞法则：“别找我们，我们找你”；即由IoC容器帮对象找相应的依赖对象并注入，而不是由对象主动去找。

关于更多的 IoC 概念，参考: 
- [维基百科](https://zh.wikipedia.org/wiki/%E6%8E%A7%E5%88%B6%E5%8F%8D%E8%BD%AC)
- [百度百科](https://baike.baidu.com/item/%E6%8E%A7%E5%88%B6%E5%8F%8D%E8%BD%AC/1158025)