---
title: ruby分布式锁
date: 2021-11-11 20:24:42
tags: [ruby]
---

```ruby
#ruby的分布式锁实现，基于redis
class Redlock
  DefaultRetryCount=3
  DefaultRetryDelay=200
  ClockDriftFactor = 0.01
  UnlockScript='
    if redis.call("get",KEYS[1]) == ARGV[1] then
        return redis.call("del",KEYS[1])
    else
        return 0
    end'

  def initialize(*server_urls)
    @servers = []
    server_urls.each{|url|
      @servers << Redis.new(:url => url)
    }
    @quorum = server_urls.length / 2 + 1
    @retry_count = DefaultRetryCount
    @retry_delay = DefaultRetryDelay
    @urandom = File.new("/dev/urandom")
  end

  def set_retry(count,delay)
    @retry_count = count
    @retry_delay = delay
  end

  def lock_instance(redis,resource,val,ttl)
    begin
      return redis.client.call([:set,resource,val,:nx,:px,ttl])
    rescue
      return false
    end
  end

  def unlock_instance(redis,resource,val)
    begin
      redis.client.call([:eval,UnlockScript,1,resource,val])
    rescue
      # Nothing to do, unlocking is just a best-effort attempt.
    end
  end

  def get_unique_lock_id
    val = ""
    bytes = @urandom.read(20)
    bytes.each_byte{|b|
      val << b.to_s(32)
    }
    val
  end

  def lock(resource,ttl)
    val = get_unique_lock_id
    @retry_count.times {
      n = 0
      start_time = (Time.now.to_f*1000).to_i
      @servers.each{|s|
        n += 1 if lock_instance(s,resource,val,ttl)
      }
      # Add 2 milliseconds to the drift to account for Redis expires
      # precision, which is 1 milliescond, plus 1 millisecond min drift
      # for small TTLs.
      drift = (ttl*ClockDriftFactor).to_i + 2
      validity_time = ttl-((Time.now.to_f*1000).to_i - start_time)-drift
      if n >= @quorum && validity_time > 0
        return {
            :validity => validity_time,
            :resource => resource,
            :val => val
        }
      else
        @servers.each{|s|
          unlock_instance(s,resource,val)
        }
      end
      # Wait a random delay before to retry
      sleep(rand(@retry_delay).to_f/1000)
    }
    return false
  end

  def unlock(lock)

    @servers.each{|s|
      unlock_instance(s,lock[:resource],lock[:val])
    }
  rescue =>e
    puts "RedLock err:" + e.to_s
  end
end

```

 #初始化分布式锁（一般在初始化程序中 config/initializers/xxx.rb）
 $distributed_locks = Redlock.new("redis://#{REDIS_HOST}:6379")


使用示例
```ruby
def self.apply_join(user_id, tag_info_id)
    # 设置重试次数和每次重试的间隔时间
    $distributed_locks.set_retry(1, 100)
    # 持有锁的时间
    tag_user_lock = $distributed_locks.lock("#{user_id}_#{tag_info_id}", 60 * 1000)
    result = false
    begin
      if tag_user_lock
        unless TagUserTag.where(user_id: user_id, tag_id: tag_info_id).first
          # 并发导致创建多条相同记录
          TagUserTag.where(user_id: user_id, tag_id: tag_info_id, status: 1).delete_all
          TagUserTag.create(user_id: user_id, tag_id: tag_info_id, status: 1)
          update_user_tag_cache_status(user_id, tag_info_id, 1)
          result = true
        else
          Rails.logger.info("该用户已经在本系统标签下，或 已提出申请")
        end
      end
      # 释放锁
      $distributed_locks.unlock(tag_user_lock)
    rescue => e
      # 释放锁
      $distributed_locks.unlock(tag_user_lock)
    end
    result
  end
```