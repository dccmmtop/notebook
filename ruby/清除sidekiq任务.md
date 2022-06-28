---
title: 清除sidekiq任务
tags: [rails]
date: 2021-08-12 23:12:03
---

sidekiq清空队列里任务的方式主要有两种，一是使用sidekiq的api，二是直接操作redis

## 一、使用sidekiq的api清空队列的任务
  sidekiq里有提供操作队列的api，首先引入

  require'sidekiq/api'

  获取所有队列：Sidekiq::Queue.all

  获取默认队列：Sidekiq::Queue.new# the "default" queue

  按名称获取队列：Sidekiq::Queue.new("mailer")

  清空队列的所有任务：Sidekiq::Queue.new.clear

  按条件来删除队列的任务：
```ruby
  queue=Sidekiq::Queue.new("mailer")

  queue.eachdo |job|

      job.klass# => 'MyWorker'  job.args# => [1, 2, 3]

      job.delete if    job.jid=='abcdef1234567890'

  end
```

## 二、直接操作redis来删除队列里的任务
首先获取配置文件config，再连接redis，这里使用了redis的Gem包
　　redis= Redis.new(:host => config['host'], :port => config['port'], :db=> config['db'], :password => config['password'])
由于queues用的是set类型的数据，所以要用srem来删除相应的数据

```ruby
redis.srem(‘queues’, ‘队列的名称’)  # 这种情况会直接删除该名称的队列
```
