---
title: linux批量重命名
date: 2021-08-10 10:12:57
---
## 通过rename命令批量重命名文件
基本语法
示例
1. 改变文件扩展名
2. 大写改成小写
3. 更改文件名模式


通过rename命令批量重命名文件
基本语法
```shell
rename [-n -v -f] <pcre> <files>
```
'pcre’是Perl兼容正则表达式，它表示的是要重命名的文件和该怎么做。正则表达式的形式是‘s/old-name/new-name/’。
‘-v’选项会显示文件名改变的细节（比如：XXX重命名成YYY）。
‘-n’选项告诉rename命令在不实际改变名称的情况下显示文件将会重命名的情况。这个选项在你想要在不改变文件名的情况下模拟改变文件名的情况下很有用。
‘-f’选项强制覆盖存在的文件。
示例
1. 改变文件扩展名
假设你有许多.jpeg的图片文件，你想要把它们的名字改成.jpg。下面的命令就会将.jpeg 文件改成 *.jpg。
`rename 's/\.jpeg/\.jpg/' *.jpeg`
2. 大写改成小写
有时你想要改变文件名的大小写，你可以使用下面的命令。
把所有的文件改成小写
`rename 'y/A-Z/a-z/'`
把所有的文件改成大写
`rename 'y/a-z/A-Z/' *`
3. 更改文件名模式
现在让我们考虑更复杂的包含子模式的正则表达式。在PCRE中，子模式包含在圆括号中，符后接上数字（比如1，$2）。

下面的命令会将‘imgNNNN.jpeg’变成‘danNNNN.jpg’。
```shell
root@root:~$ rename -v 's/img_(\d{4})\.jpeg/dan_$1.jpg/' *.jpeg
img_5417.jpeg renamed as dan_5417.jpg
img_5418.jpeg renamed as dan_5418.jpg
img_5419.jpeg renamed as dan_5419.jpg
img_5420.jpeg renamed as dan_5420.jpg
img_5421.jpeg renamed as dan_5421.jpg
img_5422.jpeg renamed as dan_5422.jpg
```
下面的命令会将‘img_000NNNN.jpeg’变成‘dan_NNNN.jpg’。
```shell
root@root:~$ rename -v 's/img_\d{3}(\d{4})\.jpeg/dan_$1.jpg/' *.jpeg
img_0005417.jpeg renamed as dan_5417.jpg
img_0005418.jpeg renamed as dan_5418.jpg
img_0005419.jpeg renamed as dan_5419.jpg
img_0005420.jpeg renamed as dan_5420.jpg
img_0005421.jpeg renamed as dan_5421.jpg
img_0005422.jpeg renamed as dan_5422.jpg
```
上面的例子中，子模式‘\d{4}’会捕捉4个连续的数字，捕捉的四个数字匹配模式对应$1, 将会用于新的文件名。