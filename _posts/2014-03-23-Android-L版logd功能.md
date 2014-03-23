---
layout: default
title: Android L版logd功能
---

{{page.title}}
======================

#### 介绍

logd是目前Android在L版本新增的一个log相关的功能,代码的相关位置在
system/core/logd目录.在Android代码的git提交记录上,关于logd的信息
只有一句话.

    logd: initial checkin.

    * Create a new userspace log daemon for handling logging messages.

目前还不能确定它的具体作用和在log系统的位置,笔者只是凭借对代码的阅读进行猜测.
logd的全部代码可以看[这里](https://android.googlesource.com/platform/system/core/+/882f856668331488d9bbaec429de7aac5d7978c9/logd)
