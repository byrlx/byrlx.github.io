---
layout: default
title: Android Log系统外传之logwrapper
---

{{page.title}}
-----------------

严格来讲，logwrapper并不属于之前写的Android的Log体系（
[logger](http://byrlx.github.io/2013/07/17/Android-Log-%E7%B3%BB%E7%BB%9F-%E4%B9%8B-Logger.html)、
[liblog](http://byrlx.github.io/2013/07/13/Android-Log-%E7%B3%BB%E7%BB%9F%E4%B9%8B-liblog.html)、
[logcat](http://byrlx.github.io/2013/07/10/Android-Log-%E7%B3%BB%E7%BB%9F%E4%B9%8B-logcat.html)
），但是呢，它多多少少又与这套体系有些关系，所以将其称之为“外传”。

什么是logwrapper？如果你写了一个android程序，使用了一些标准输出函数（printf），
但是有时候你无法看到这些输出（例如你写了一个native开机启动程序，
那你应该没办法在adb shell中看到你的输出吧）。
那么使用logwrapper可以将你的程序的标准输出重定向到android log或kernel log中，
就像是你调用了这些log函数(ALOGI或printk）一样。
		
例如，你在adb shell中输入‘logwrapper ls’，
终端上不会显示任何内容，ls的输出被重定向到了logger中，
通过logcat命令把logger的内容抓到文件中，可以看到ls的输出。
如下图。

使用logwrapper后，ls的结果没有输出到标准输出。
![ls with logwrapper]({{root_url}}/images/ls.png "lslogwrapper")

在logcat抓的log中发现了上面ls命令的结果。
![logcat with logwrapper]({{root_url}}/images/logwrapper.png "logwrapper")

