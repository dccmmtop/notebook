# adb获取屏幕UI元素

执行命令:

```shell
adb shell uiautomator dump /sdcard/ui.xml
```

可以获取当前应用的activity屏幕上所有控件的层级信息并保存在sdcard下ui.xml文件里面.

然后通过解析ui.xml文件就可以拿到想要的控件信息.

原理:
调用安卓设备系统文件中/system/bin/uiautomator.jar包执行dump指令.
