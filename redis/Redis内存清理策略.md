---
title: Redis内存清理策略
date: 2023-03-30 08:14:20
tags: [redis]
---

## 三种清触策略

- 被动清除
  当读写一个已经过期的key时，会触发惰性删除策略，直接删除掉这个过期的key
- 主动删除
  由于惰性删除无法保证冷数据及时清理，所以redis会定期主动淘汰**已经过期**的部分key，默认是每100ms一次。这里只是部分已过期的key，所以可能会出现部分key已经过期，但没有清理掉的情况，导致内存并没有释放
- maxmemory 限定
  当前内存使用超过 maxmemory 限定时，触发主动清理策略
  
主动清理策略在 redis 4.0 之前一共实现了6种内存淘汰算法，4.0 之后，又增加了2中，共8种。可以按照针对key是否设置过期时间分为两大类:

### 针对设置了过期时间的key

1. volatile-ttl: 会针对设置了过期时间的key，根据过期时间的先后进行清理，越早过期的，越先被删除
2. volatile-random: 在设置了过期时间的key中，随机选择删除
3. volatile-lru: 会使用lru算法来选择设置了过期时间的key进行删除 
4. volatile-lfu: 会使用lfu算法来选择设置了过期时间的key进行删除 

#### 针对所有的key

5. allkeys-random: 从所有的键值对中随机选择并删除
6. allkeys-lru: 从所有的键值对中使用lru算法选择并删除
7. allkeys-lfu: 从所有的键值对中使用lfu算法选择并删除

### 不处理

8. noeviction：不会剔除任何数据，拒绝所有写入操作并返回客户端错误信息"(error) OOM command not allowed when used memory"，此时Redis只响应读操作。



## LRU 算法（Least Recently Used，最近最少使用）
淘汰很久没被访问过的数据，以最近一次访问时间作为参考。

## LFU 算法（Least Frequently Used，最不经常使用）
淘汰最近一段时间被访问次数最少的数据，以次数作为参考。


## 实际应用

当存在热点数据时，LRU的效率很好，但偶发性的、周期性的批量操作会导致LRU命中率急剧下降，缓存污染情况比较严重。这时使用LFU可能更好点。

根据自身业务类型，配置好maxmemory-policy(默认是noeviction)，推荐使用volatile-lru。如果不设置最大内存，当 Redis 内存超出物理内存限制时，内存的数据会开始和磁盘产生频繁的交换 (swap)，会让 Redis 的性能急剧下降。

当Redis运行在主从模式时，只有主结点才会执行过期删除策略，然后把删除操作”del key”同步到从结点删除数据。
