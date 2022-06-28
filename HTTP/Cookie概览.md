---
title: Cookie概览
date: 2021-10-26 23:28:06
tags: [HTTP]
---
## 会话 cookie 与持久 cookie
没有设置Expires字段的cookie通常称为会话cookie或者临时cookie，这种cookie在浏览器关闭的时候就会自动被移除。相对而言，设置了Expires字段的cookie通常称为持久cookie，这种cookie会一直存在，直到指定的过期时间来临或者被手动删除为止。
## cookie 过期时间
Expires字段和MaxAge字段都可以用于设置cookie的过期时间，其中Expires字段用于明确地指定cookie应该在什么时候过期，而MaxAge字段则指明了cookie在被浏览器创建出来之后能够存活多少秒。之所以会出现这两种截然不同的过期时间设置方式，是因为不同浏览器使用了各不相同的cookie实现机制，跟Go语言本身的设计无关。虽然HTTP 1.1中废弃了Expires，推荐使用MaxAge来代替Expires，但几乎所有浏览器都仍然支持Expires；而且，微软的IE6，IE7和IE8都不支持MaxAge。为了让cookie在所有浏览器上都能够正常地运作，一个实际的方法是只使用Expires，或者同时使用Expires和 МаxAge.