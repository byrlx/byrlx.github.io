---
layout: default
title: 使用git管理perforece
---

{{page.title}}
-------------------------

本文主要介绍怎样使用git-p4这个脚本，实现用git管理perforce服务器的代码。

公司的代码管理一直使用perforce，一款商业软件。因为一直在学习用git，所以就像可不可以通过git来管理perforce的代码库，
然后就找到了git-p4这款软件，果然是只有你想不到，没有git社区做不到。

#### 0. 安装git

还没开始使用git？不是吧.......

#### 1. 创建perforce配置文件

如果你常用p4 命令行，你一定已经有一个这样的file了。否则......

创建一个文件，保存如下信息，并在bashrc中引用它

  # p4config
  export P4PORT=your p4 server address:port
  export P4USER=account
  export P4CLIENT=local p4 workspace
  
  #bashrc
  source  p4config
