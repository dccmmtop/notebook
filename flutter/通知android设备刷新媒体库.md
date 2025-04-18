---
title: 通知android设备刷新媒体库
date: 2025-04-18 07:59:46
tags: [flutter]
---

### 需求
将应用生成的、下载的文件立刻显示在文件管理器中

### 实现

- media_scanner.dart
```dart
import 'dart:async';

import 'package:flutter/services.dart';

class MediaScanner {
  /// Define Method Channel
  static const MethodChannel _channel = MethodChannel('media_scanner');

  /// Path : Path of Image/Video
  static Future<String?> loadMedia({String? path}) async =>
      await _channel.invokeMethod('refreshGallery', {"path": path});
}
```

### 使用示例
```dart
  Future<void> _notifyMediaScanner(String filePath) async {
    try {
      // 判断是不是android设备
      if (Platform.isAndroid) {
        // 通知媒体库更新
        await MediaScanner.loadMedia(path: filePath);
        logger.i("媒体库已更新");
      }else{
        logger.i("非android设备");
      }
    } catch (e) {
      logger.i("通知媒体库时出错: $e");
    }
  }
```




> 联系方式: dccmmtop@foxmail.com