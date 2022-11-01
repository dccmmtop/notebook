## @ComponentScan

- 启用组件扫描
- 默认扫描与配置类相同的包以及子包

### 如何扫描指定的包

- @ComponentScan("包名")
- 扫描一组包： `@ComponentScan(basePackages={"xxx","xxx"}) ` 
 
这种两种方式都是传入字符串，无法方便的重构。因为我们的编辑器一般不会解析你的字符串值，可以使用下面方式：

- 扫描类和接口： `@ComponentScan(basePackageClasses={xxx.class, xxxx.class}) ` 这些类所在的包会作为组件扫描的基础包，可以为需要扫描的包中添加一个空接口，标记该包需要扫描，这种方式避免了传入字符串，方便重构修改

## @ContextConfiguration(classes=xxx.class)

需要在 xxx.class 中加载配置

## @Component

向容器中注册组件

- bean 的名字默认是类名首字母小写
- 也可以指定： @Component("xxx")
- @Named 可以替代 @Component

## @Autowired

- 用在构造器上 当 Spring 去创建该类的 bean 时，会调用这个构造方法，同时传入一个 满足参数的 bean
  ```java
  Class User {
      private Car car;
     // 会使用这个方法去构造 bean, 而不是无    参构造器
      @Autowired
      public User(Car car){
          this.car = car;
      }
  }
  ```

- 用在 Setter 方法上

- 其实可以用在类的任何方法上，Spring 尝试满足方法参数上声明的依赖，如果找不到对应的 bean 就会抛出异常

- @Autowired(required=false)  即使没找到也不会抛出异常，会传入 Null. 可能会导致空指针异常

- 如果有多个 bean 都能满足，会抛出异常

- 可以使用 Inject 替换，Inject 是 java 中依赖注入规范

## @Bean

- 显示配置 Bean, 可以把第三方对象设置成 Bean，因为我们无法直接在第三方类上添加@Component 注解
- bean Id 默认是方法名，可以指定：`@Bean("xxx")`
  ```java
  @Configuration
  @ComponentScan
  public class AutowiredDemoConfig {
      /**
      * User 是引入的第三方工具，无法修改 User 类，在类名上加 @Component 注解
      */

      @Bean
      public User user(){
          return new User(10,"dc1");
      }
  }
  ```

## @Profile("dev")
- 和@Bean 一起使用，当 dev 环境上才会创建 bean
- 配置
  `spring.profiles.default=dev`  或者 `spring.profiles.active=dev` 激活 dev 环境，如果没有激活的环境，只会创建那些没有定义在 profile 中的 bean
- 从 Spring 4 开始，依赖 @Conditional 注解

## @Conditional
- Since 4.0
- 条件化的 bean
- 用到带有@Bean 的注解的方法上
- 给定条件的结果为 true 时，创建 bean  否则不创建
- 需要实现 Conditional 接口中的 matches 方法

## @Primary

- 处理自动装配的歧义
- 如果一个 Bean 是接口，系统中有多个实现类。注入时就会有歧义，抛出异常
- @Primary 用在 Bean 上，标记这个 bean 是首选的，发生歧义时首选它， 不会报错
- 缺点： 只能使用其中一个 bean，无法指定注入哪个，@Qualifier 解决这个问题

  示例： 
  ```java
  @RunWith(SpringJUnit4ClassRunner.class)
  @ContextConfiguration(classes = AutowiredDemoConfig.class)
  public class QualifierDemo {
    @Autowired
    private Dessert dessert;

    @Test
    public void eat(){
        dessert.getName();
    }

  }

  /**
  * Cake IceCream 都实现了 Dessert
  */
  interface Dessert{
    String getName();
  }

  @Component
  @Primary // 会优先注入 Cake
  class Cake implements Dessert {
    public String getName() {
        String name = "Cake";
        System.out.println(name);
        return name;
    }
  }

  @Component
  class IceCream implements Dessert{

    public String getName() {
        String name = "IceCream";
        System.out.println(name);
        return name;
    }
  }

  ```

## @Qualifier("xxx bean name")
- 与 @Autowired 一起使用时直接指定 bean 的名字进行装配： 
- 与 @Component 一起使用，可以设置 bean 的名字
- 与 @Bean 一起使用，可以设置 bean 的名字

## @Scope bean 的作用域
默认所有的 bean 都是单例的。Spring 定义了多种作用域，包括：
- 单例 (Singleton): 整个应用中只创建一个 bean 实例
- 原型 (Prototype): 每次注入或者通过 Spring 应用上下文获取的时候，都会创建一个新的 bean。
- 会话 (Session): 在 Web 应用中，为每个会话创建一个实例
- 请求 (Request): 在 Web 应用中，为每个请求创建一个实例

### 示例
使用 @Scope 注解，改变bean的作用域
```java
@RunWith(SpringJUnit4ClassRunner.class)
@ComponentScan
@ContextConfiguration(classes = ScopeDemo.class)
public class ScopeDemo {
    @Autowired
    @Qualifier("singleSTU")
    private Student s1;

    @Autowired
    @Qualifier("singleSTU")
    private Student s2;

    @Autowired
    @Qualifier("prototypeSTU")
    private Student s3;

    @Autowired
    @Qualifier("prototypeSTU")
    private Student s4;

    @Test
    public  void scopeDemo(){
        Assert.assertEquals("s1 s2 是单例作用域，两者应该相等:", s1.hashCode(), s2.hashCode());
        Assert.assertNotEquals("s3 s4 是原型作用域，两者应该不相等:", s3.hashCode(), s4.hashCode());
    }
}

@Configuration
class Student {

    private int age;

    /**
     * 默认是单例作用域
     * @return
     */
    @Bean("singleSTU")
    public Student stu(){
        Random random = new Random();
        Student s1 = new Student();
        s1.setAge(random.nextInt(100));
        return s1;
    }

    /**
     * 设置原型作用域
     * @return
     */
    @Bean("prototypeSTU")
    @Scope(ConfigurableBeanFactory.SCOPE_PROTOTYPE)
    public Student stu1(){
        Random random = new Random();
        Student s1 = new Student();
        s1.setAge(random.nextInt(100));
        return s1;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }
}
```

  
## 运行时注入外部值

把配置文件中的字段注入到对象中 

### Enviroment

通过注解@PropertySource("xxx")讲配置文件中的信息注入到Enviorment 对象中:

```java
@RunWith(SpringJUnit4ClassRunner.class)
@ComponentScan
@ContextConfiguration(classes = EnviromentDemo.class)
public class EnviromentDemo {

    @Autowired
    private Mysql mysql;

    @Test
    public void testDataSource(){
        System.out.println(mysql.getPort());
    }

}

@Configuration
@PropertySource("classpath:/app.properties")// 将配置文件中的字段加载到 Environment 中，稍后可以通过 Environment 对象获取
class DataSource {

    @Autowired
    Environment env;

    @Bean
    public Mysql mysql(){
        // 获取对应的字段值，getProperty 更多用法参考源码
        return  new Mysql(env.getProperty("mysql.port", Integer.class), env.getProperty("mysql.host"));

    }
}
 class Mysql {
     private int port;
     private String host;

     public Mysql(int port, String host) {
         this.port = port;
         this.host = host;
     }

     public int getPort() {
         return port;
     }

     public void setPort(int port) {
         this.port = port;
     }

     public String getHost() {
         return host;
     }

     public void setHost(String host) {
         this.host = host;
     }
 }

```

### 通过属性占位符装配

还可以通过 ${} 占位符读取配置文件中的字段，注入到字段中； 如下:

```java
@RunWith(SpringJUnit4ClassRunner.class)
@ComponentScan
@ContextConfiguration(classes = ValueDemo.class)
public class ValueDemo {

    @Autowired
    private Mysql1 mysql;

    @Test
    public void testDataSource(){
        System.out.println(mysql.getPort());
    }

}

@Configuration
class DataSource1 {

    @Autowired
    Environment env;

    @Bean // 这个bean 是必须的。可以解析占位符,自动查找
    public  static PropertySourcesPlaceholderConfigurer  propertySourcesPlaceholderConfigurer(){
        return new PropertySourcesPlaceholderConfigurer();
    }

    @Bean
    // ${} 占位符方式注入
    public Mysql1 mysql(@Value("${mysql.port}") int port,@Value("${mysql.host}") String host){
        // 获取对应的字段值，getProperty 更多用法参考源码
        return  new Mysql1(port, host);

    }
}

class Mysql1 {
    private int port;
    private String host;

    public Mysql1(int port, String host) {
        this.port = port;
        this.host = host;
    }

    public int getPort() {
        return port;
    }

    public void setPort(int port) {
        this.port = port;
    }

    public String getHost() {
        return host;
    }

    public void setHost(String host) {
        this.host = host;
    }
}
```