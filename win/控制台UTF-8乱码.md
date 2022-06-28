# 控制台UTF-8乱码

Windows cmd默认的是GBK编码，不过GO字符串默认为utf-8编码，

在属性里面没有办法修改

我们可以使用chcp 命令来进行修改,

chcp 显示当前代码页
chcp 65001  就是切换到UTF-8代码页  
chcp 936 可以换回默认的GBK  
修改这样修改了还不行，请修改一下字体 

其它编码可以查看百度http://baike.baidu.com/view/1244987.htm
