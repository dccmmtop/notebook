# baloo_file内存占用高

top查看了一下，有一个 /usr/bin/baloo_file 一直会使用很多内存
查了一下发现是因为新版本的KDE引入的 /usr/bin/baloo_file 导致。

快速解决办法就是把 baloo_file 和 baloo_file_extractor 这两个文件备份一下，然后重新建立一个到 /bin/true 的链接，如下：

```shell
$ sudo mv /usr/bin/baloo_file_extractor /usr/bin/baloo_file_extractor.bak
$ sudo ln -s /bin/true /usr/bin/baloo_file_extractor
$ sudo mv /usr/bin/baloo_file /usr/bin/baloo_file.bak
$ sudo ln -s /bin/true /usr/bin/baloo_file
```