---
title: redis 使用规范与性能优化
date: 2023-03-27 23:11:51
tags: [redis]
---

## 键的设计

- 兼顾可读性和可管理性
以业务名（或数据库名）为前缀（防止 key 冲突），用冒号分隔，比如业务名：表名：id
- 简洁性
保证语义的前提下，控制 key 的长度，当 key 较多时，内存占用也不容忽视，例如： ` user:{uid}:friends:messages:{mid}` 简化为 `u:{uid}:fr:m:{mid} `
- 不要包含特殊字符（强制）

## value 设计

####  拒绝 bigkey （强制）

在 Redis 中，一个字符串最大 512MB，一个二级数据结构（例如 hash、list、set、zset）可以存储大约 40 亿个 (2^32-1) 个元素，但实际中如果下面两种情况，就会认为它是 bigkey。

- 字符串类型：它的 big 体现在单个 value 值很大，一般认为超过 10KB 就是 bigkey。
- 非字符串类型：哈希、列表、集合、有序集合，它们的 big 体现在元素个数太多。

一般来说，string 类型控制在 10KB 以内，hash、list、set、zset 元素个数不要超过 5000。 反例：一个包含 200 万个元素的 list。

非字符串的 bigkey，不要使用 del 删除，使用 hscan、sscan、zscan 方式渐进式删除，同时要注意防止 bigkey 过期时间自动删除问题（例如一个 200 万的 zset 设置 1 小时过期，会触发 del 操作，造成阻塞）

#### bigkey 的危害：

1. 导致 redis 阻塞
2. 网络拥塞
    bigkey 也就意味着每次获取要产生的网络流量较大，假设一个 bigkey 为 1MB，客户端每秒访问量为 1000，那么每秒产生 1000MB 的流量，对于普通的千兆网卡（按照字节算是 128MB/s） 的服务器来说简直是灭顶之灾，而且一般服务器会采用单机多实例的方式来部署，也就是说一个 bigkey 可能会对其他实例也造成影响，其后果不堪设想。
3. 过期删除
    有个 bigkey，它安分守己（只执行简单的命令，例如 hget、lpop、zscore 等），但它设置了过期时间，当它过期后，会被删除，如果没有使用 Redis 4.0 的过期异步删除 (lazyfree-lazy-expire yes)，就会存在阻塞 Redis 的可能性。
bigkey 的产生：
#### 一般来说，bigkey 的产生都是由于程序设计不当，或者对于数据规模预料不清楚造成的，来看几个例子：
1. 社交类：粉丝列表，如果某些明星或者大 v 不精心设计下，必是 bigkey。
2. 统计类：例如按天存储某项功能或者网站的用户集合，除非没几个人用，否则必是 bigkey。
3. 缓存类：将数据从数据库 load 出来序列化放到 Redis 里，这个方式非常常用，但有两个地方需要注意，第一，是不是有必要把所有字段都缓存；第二，有没有相关关联的数据，有的同学为了图方便把相关数据都存一个 key 下，产生 bigkey。

#### 如何优化 bigkey
1. 拆
big list： list1、list2、...listN 就是把大列表分成几个小列表存储
big hash：可以讲数据分段存储，比如一个大的 key，假设存了 1 百万的用户数据，可以拆分成 200 个 key，每个 key 下面存放 5000 个用户数据

2. 如果 bigkey 不可避免，也要思考一下要不要每次把所有元素都取出来（例如有时候仅仅需要 hmget，而不是 hgetall)，删除也是一样，尽量使用优雅的方式来处理。

### 选择合适的数据类型

### 控制key的生命周期，redis不是垃圾桶
建议使用expire设置过期时间(条件允许可以打散过期时间，防止集中过期)。

## 命令的使用

### 关注元素数量
例如hgetall、lrange、smembers、zrange、sinter等并非不能使用，但是需要明确N的值。有遍历的需求可以使用hscan、sscan、zscan代替。

### 禁用危险命令
禁止线上使用keys、flushall、flushdb等，通过redis的rename机制禁掉命令，或者使用scan的方式渐进式处理。

### 批量操作提升效率

- 原生命令：例如mget、mset。
- 非原生命令：可以使用pipeline提高效率。

### 不建议使用自带事务
Redis事务功能较弱，不建议过多使用，可以用lua替代

## 客户端的使用

### 避免多个业务使用一个redis服务(推荐)
多个不相干的业务应该使用不同的redis服务，公共数据做服务化

### 使用带有连接池的客户端
可以有效控制连接数量，同时提高效率，标准使用方式如下:

```java
JedisPoolConfig jedisPoolConfig = new JedisPoolConfig();
jedisPoolConfig.setMaxTotal(5);
jedisPoolConfig.setMaxIdle(2);
jedisPoolConfig.setTestOnBorrow(true);

JedisPool jedisPool = new JedisPool(jedisPoolConfig, "192.168.0.60", 6379, 3000, null);

Jedis jedis = null;
try {
    jedis = jedisPool.getResource();
    //具体的命令
    jedis.executeCommand()
} catch (Exception e) {
    logger.error("op key {} error: " + e.getMessage(), key, e);
} finally {
    //注意这里不是关闭连接，在JedisPool模式下，Jedis会被归还给资源池。
    if (jedis != null) 
        jedis.close();
}
```

#### 连接池参数含义：

| 序号 | 参数名             | 含义                                                                          | 默认值           | 使用建议                                          |
| ---- | ------------------ | ----------------------------------------------------------------------------- | ---------------- | ------------------------------------------------- |
| 1    | maxTotal           | 资源池中最大连接数                                                            | 8                | 设置建议见下面                                    |
| 2    | maxIdle            | 资源池允许最大空闲的连接数                                                    | 8                | 设置建议见下面                                    |
| 3    | minIdle            | 资源池确保最少空闲的连接数                                                    | 0                | 设置建议见下面                                    |
| 4    | blockWhenExhausted | 当资源池用尽后，调用者是否要等待。只有当为true时，下面的maxWaitMillis才会生效 | true             | 建议使用默认值                                    |
| 5    | maxWaitMillis      | 当资源池连接用尽后，调用者的最大等待时间(单位为毫秒)                          | -1：表示永不超时 | 不建议使用默认值                                  |
| 6    | testOnBorrow       | 向资源池借用连接时是否做连接有效性检测(ping)，无效连接会被移除                | false            | 业务量很大时候建议设置为false(多一次ping的开销)。 |
| 7    | testOnReturn       | 向资源池归还连接时是否做连接有效性检测(ping)，无效连接会被移除                | false            | 业务量很大时候建议设置为false(多一次ping的开销)。 |
| 8    | jmxEnabled         | 是否开启jmx监控，可用于监控                                                   | true             | 建议开启，但应用本身也要开启                      |

#### 优化建议

##### maxTotal: 最大连接数，早期叫做 maxActive
如何设置这个值是比较难回答的，没有固定的计算方式，考虑的因素比较多：
- 业务希望redis的并发量
- 客户端执行命令的时间
- redis 资源，应用的个数 * maxTotal < redis 的最大连接数 maxclients
- 资源开销，例如虽然希望控制空闲连接(连接池此刻可马上使用的连接)，但是不希望因为连接池的频繁释放创建连接造成不必靠开销。

例子：
> 假设: 一次命令时间（borrow|return resource + Jedis执行命令(含网络) ）的平均耗时约为1ms，一个连接的QPS大约是1000, 业务期望的QPS是50000
>
> 那么理论上需要的资源池大小是50000 / 1000 = 50个。但事实上这是个理论值，还要考虑到要比理论值预留一些资源，通常来讲maxTotal可以比理论值大一些。
> 但这个值不是越大越好，一方面连接太多占用客户端和服务端资源，另一方面对于Redis这种高QPS的服务器，一个大命令的阻塞即使设置再大资源池仍然会无济于事。

#### maxIdle 和 minIdel

maxIdle 实际上才是业务需要的最大连接数，maxTotal 是为了给出结余量，所以maxIdele 不要设置的太小，否则会不断的发生新建连接，释放连接的开销。 

**连接池的最佳性能是 maxTotal = maxIdle** 这样就避免连接池伸缩带来的性能干扰，但是在并发量不大的时候，或者 maxTotal 设置过高，会导致不必要的连接资源浪费，一般推荐 maxIdle 按照上面的计算方式设置，maxTotal 可以再放大一倍。

minIdle（最小空闲连接数），与其说是最小空闲连接数，不如说是"至少需要保持的空闲连接数"，在使用连接的过程中，如果连接数超过了minIdle，那么继续建立连接，如果超过了maxIdle，当超过的连接执行完业务后会慢慢被移出连接池释放掉

### 连接池预热

如果系统刚启动完，就马上有很多请求过来，那么可以给连接池做预热,比如快速的创建一些redis连接，执行简单命令，如 ping, 快速的将连接池中的连接提升到 minIdel 的数量

示例代码:
```java
List<Jedis> minIdleJedisList = new ArrayList<Jedis>(jedisPoolConfig.getMinIdle());

for (int i = 0; i < jedisPoolConfig.getMinIdle(); i++) {
    Jedis jedis = null;
    try {
        jedis = pool.getResource();
        minIdleJedisList.add(jedis);
        jedis.ping();
    } catch (Exception e) {
        logger.error(e.getMessage(), e);
    } finally {
        //注意，这里不能马上close将连接还回连接池，否则最后连接池里只会建立1个连接。。
        //jedis.close();
    }
}
//统一将预热的连接还回连接池
for (int i = 0; i < jedisPoolConfig.getMinIdle(); i++) {
    Jedis jedis = null;
    try {
        jedis = minIdleJedisList.get(i);
        //将连接归还回连接池, 注意这里是规范连接，而不是关闭
        jedis.close();
    } catch (Exception e) {
        logger.error(e.getMessage(), e);
    } finally {
    }
}
```