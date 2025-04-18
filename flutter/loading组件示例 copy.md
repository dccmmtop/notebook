---
title: loading 组件示例
date: 2025-04-18 07:49:53
tags: [flutter]
---

处理一些耗时的操作时，同时需要用户等待可以使用弹框加`flutter_spinkit`来实现 loading 效果

**【注意】**
如果耗时的操作是 cpu 密集型的，需要使用`compute()`来优化，防止阻塞线程，造成卡顿，甚至 loading 组件无法显示，关于 flutter 线程模型以及 compute 的使用请查看《Flutter 线程模型》

### loading 组件
```dart
Future<void> _loading(BuildContext context) async {
// 显示加载框
showDialog(
    context: context,
    // 用户无法通过点击外部关闭对话框
    barrierDismissible: false,
    builder: (context) {
    return AlertDialog(
        content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            SizedBox(height: 5),
            // 选择不同的加载框
            SpinKitFadingCircle(color: Colors.blue, size: 50.0),
            SizedBox(height: 16),
            Text("文件处理中，请稍候。.."),
        ],
        ),
    );
    },
);

```

> 联系方式：dccmmtop@foxmail.com