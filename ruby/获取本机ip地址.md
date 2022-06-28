---
title: 获取本机ip地址
tags: [ruby]
date: 2021-08-12 23:12:27
---

```ruby
require "socket"
local_ip = UDPSocket.open {|s| s.connect("1.1.1.1", 1);s.addr.last}
```
