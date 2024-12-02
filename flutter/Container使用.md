---
title: Container 使用
date: 2024-12-02 22:50:04
tags: [flutter]
---

### Container
它可以包含其他 Widget，并允许你控制其布局、大小、边距、填充、装饰等属性

Container 有许多属性，主要包括：

- alignment：设置子 Widget 的对齐方式。
- width 和 height：设置容器的宽度和高度。
- padding：设置内部填充。
- margin：设置外部边距。
- color：设置背景颜色。
- decoration：用于更复杂的背景样式，可以设置边框、阴影、渐变等。


### 示例
```dart
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("App Title")),
        body: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 设置容内部元素的对齐方式
      alignment: Alignment.center,
      height: 300,
      width: 300,
      // 修饰
      decoration: BoxDecoration(
          // 设置边框圆角，四个角一样
          // borderRadius: const BorderRadius.all(Radius.circular(20)),
          // 左右两边的圆角度分别设置
          // borderRadius: const BorderRadius.vertical(top: Radius.circular(30), bottom: Radius.circular(80)),
          // 上下两边的圆角度分别设置
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30), bottom: Radius.circular(80)),
          color: Colors.yellow,
          // 设置边框
          border: Border.all(
            color: Colors.red,
            width: 5,
          )),

      child: const Text(
        "测试 Container",
        style: TextStyle(color: Colors.black, fontSize: 30),
      ),
    );
  }
}
```

> 联系方式：dccmmtop@foxmail.com