---
layout: default
title: Android L 版本Log系统之 概述
---

{{page.title}}
-------------------

因为在公司负责Android Log系统的维护工作,所以L版本发布后,
一直在跟踪L版本Log系统的相关变化.

L版本的Log系统变化很大, 主要是引入了Native 层的Logd机制来
KK及之前版本的Logger机制. 由于Logd的引入,导致liblog和logcat
的代码都做了很大的修改.

这段时间会将对L版本log系统的学习陆续发表文章,主要包括:

1. Logd介绍
2. Logd代码分析
3. Liblog的修改
4. Logcat的修改.

L版本Log系统相关代码:

1. [logd](https://android.googlesource.com/platform/system/core/+/master/logd/)
2. [liblog](https://android.googlesource.com/platform/system/core/+/master/liblog/)
3. [logcat](https://android.googlesource.com/platform/system/core/+/master/logcat/)
