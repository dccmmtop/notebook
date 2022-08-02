# 搭建redis哨兵模式
头脑风暴#
出于学习目的，您可以很轻松地在docker环境下运行redis的单个实例，但是如果您需要在生产环境中运行它，那么必须将Redis部署为HA(High Avaliable)模式。

Redis Sentinel为Redis提供高可用性，这意味着使用Sentinel可以创建Redis HA部署，该部署可以在无需人工干预的情况下抵抗某些类型的故障。

Redis Sentinel提供的主要功能是：

当主节点发生故障时，它将自动选择一个备用节点并将其升级为主节点。
它是如何做到的，它会定期检查Redis实例的运行状况和运行状况，还会将新的主服务器通知给客户端和从服务器。
使用的是带有领导者选举算法的gossip协议。

Sentinel还充当客户端发现的中心授权来源，客户端连接到Sentinel以获取主节点的地址。


本文以自己的亲身经历，使用Docker-compose搭建一个Redis Sentinel模型（1:master-2:slave:3:sentinel）

Docker-compose搭建Redis Sentinel#
Redis Sentinel是针对原始Master/Slave模型而衍生的高可用模型。
我们为便于灵活部署,先易后难，先搭建Redis Master/Slave模型，再搭建Redis Sentinel模型。

文件组织格式如下
```shell
redis-sentinel
├── redis
│   └── docker-compose.yml
└── sentinel
    ├── docker-compose.yml
    ├── sentinel1.conf
    ├── sentinel2.conf
    ├── sentinel3.conf
    └── sentinel.conf
```
1. Master/Slave#
进入Redis文件夹，创建docker-compose.yml文件，
下面的Compose文件设置了1Master 2Slave

```yml
version: '3'
services:
  master:
    image: redis
    container_name: redis-master
    command: redis-server --requirepass redis_pwd  --masterauth redis_pwd
    ports:
      - 6380:6379
  slave1:
    image: redis
    container_name: redis-slave-1
    ports:
      - 6381:6379
    command:  redis-server --slaveof redis-master 6379 --requirepass redis_pwd --masterauth redis_pwd
  slave2:
    image: redis
    container_name: redis-slave-2
    ports:
      - 6382:6379
    command: redis-server --slaveof redis-master 6379 --requirepass redis_pwd --masterauth redis_pwd
```
注意，如果设置了Redis客户端访问密码requirepass， 那么也要设置相同的副本集同步密码masterauth。
另外我们后面使用哨兵模式能够完成故障转移，现有的Master可能会变成Slave，故在当前Master容器中也要携带masterauth参数。

可在容器内使用 config get [Param] 命令验证测试

执行docker-compose up -d会产生3个Redis容器，分别映射到宿主机6380、6381、6382端口， 默认连接在redis-default网桥。

docker ps输出如下：

fe2eb7a5cce9    redis    "docker-entrypoint.s…"   2 hours ago         Up 2 hours            0.0.0.0:6382->6379/tcp               redis-slave-2
4c280aa6dc09    redis    "docker-entrypoint.s…"   2 hours ago         Up 2 hours            0.0.0.0:6381->6379/tcp               redis-slave-1
91b83143b7c1    redis    "docker-entrypoint.s…"   2 hours ago         Up 2 hours            0.0.0.0:6380->6379/tcp               redis-master
2. Redis Sentinel#
很明显我们即将搭建的Sentinel容器需要能访问到以上3个容器，故需要在形成Sentinel的Dokcer-compose 使用外置的redis-default网桥.

2.1 进入到sentinel文件夹，创建docker-compose.yml#
version: '3'
services:
  sentinel1:
    image: redis
    container_name: redis-sentinel-1
    ports:
      - 26379:26379
    command: redis-sentinel /usr/local/etc/redis/sentinel.conf
    volumes:
      - ./sentinel1.conf:/usr/local/etc/redis/sentinel.conf
  sentinel2:
    image: redis
    container_name: redis-sentinel-2
    ports:
    - 26380:26379
    command: redis-sentinel /usr/local/etc/redis/sentinel.conf
    volumes:
      - ./sentinel2.conf:/usr/local/etc/redis/sentinel.conf
  sentinel3:
    image: redis
    container_name: redis-sentinel-3
    ports:
      - 26381:26379
    command: redis-sentinel /usr/local/etc/redis/sentinel.conf
    volumes:
      - ./sentinel3.conf:/usr/local/etc/redis/sentinel.conf
networks:
  default:
    external:
      name: redis_default
2.2 创建哨兵文件，将如下内容拷贝进去：#
port 26379
dir /tmp
sentinel monitor mymaster 172.20.0.3 6379 2
sentinel auth-pass mymaster redis_pwd
sentinel down-after-milliseconds mymaster 30000
sentinel parallel-syncs mymaster 1
sentinel failover-timeout mymaster 180000
sentinel deny-scripts-reconfig yes
注意，以上 172.20.0.3是之前Redis Master/slave启动之后Master节点的IP，通过docker inspect [containerIP]获取, 这里我们要配合设置Master/Slave访问密码。

2.3 将哨兵文件复制三份，Volume进Sentinel容器#
sudo cp sentinel.conf sentinel1.conf
sudo cp sentinel.conf sentinel2.conf
sudo cp sentinel.conf sentinel3.conf
docker-compose up -d生成3个Sentinel容器。
此时docker ps显示如下：

80f4b776f5dd        redis    "docker-entrypoint.s…"   58 minutes ago      Up 57 minutes         6379/tcp, 0.0.0.0:26380->26379/tcp   redis-sentinel-2
3a1bcdc06253        redis    "docker-entrypoint.s…"   58 minutes ago      Up 57 minutes         6379/tcp, 0.0.0.0:26379->26379/tcp   redis-sentinel-1
3bada23b572e        redis    "docker-entrypoint.s…"   58 minutes ago      Up 57 minutes         6379/tcp, 0.0.0.0:26381->26379/tcp   redis-sentinel-3
fe2eb7a5cce9        redis    "docker-entrypoint.s…"   2 hours ago         Up 2 hours            0.0.0.0:6382->6379/tcp               redis-slave-2
4c280aa6dc09        redis    "docker-entrypoint.s…"   2 hours ago         Up 2 hours            0.0.0.0:6381->6379/tcp               redis-slave-1
91b83143b7c1        redis    "docker-entrypoint.s…"   2 hours ago         Up 2 hours            0.0.0.0:6380->6379/tcp               redis-master
验证#
Master/Slave副本集
进入Master容器，确认两个Slave容器已经连接。


Redis Sentinel
进入其中一个Sentinel容器，确认Master、2个Slave、另外2个Sentinel


flags: master表明master正常运作，异常情况会显示s-down,o-down
num-slaves：侦测到2个Slave副本集
num-other-sentinels：除此之外，还有2个哨兵

Redis Sentinel高可用
自行停止 master容器，等待10s，进入任意sentinel容器，使用sentinel master mymaster命令观察主节点变化
总结输出#
当初做这个部署，曾经尝试采用阿里云的redis-sentinel docker-compose方式，发现其使用的是docker-compose scale特性，不会在宿主机暴露sentinel容器节点，导致Redis客户端无法定位sentinel。
结合网上一些资料，摸索出渐进式部署 && 共享网桥的方式部署Redis Sentinel, 本人亲测有效。

项目开源地址如下，大家可积极使用。

https://github.com/zaozaoniao/Redis-sentinel-with-docker-compose
