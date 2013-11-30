---
layout: default
title: 使用 git 管理 perforece
---

{{page.title}}
-------------------------

本文主要介绍怎样使用 git-p4 这个脚本，实现用 git 管理 perforce 服务器的代码。

公司的代码管理一直使用perforce，一款商业软件。因为一直在学习用git，所以就像可不可以通过git来管理perforce的代码库，
然后就找到了git-p4这款软件，果然是只有你想不到，没有git社区做不到。

#### 0. 安装git && git-p4

还没开始使用git？不是吧.......

安装完 git 后，在 bin 目录下可以找到 git-p4 这支文件（1.8以上的版本可以，旧版本没有确认过）

#### 1. 创建perforce配置文件

如果你常用p4 命令行，你一定已经有一个这样的file了。否则......

创建一个文件，保存如下信息，并在bashrc中引用它

  # p4config
  export P4PORT=your p4 server address:port
  export P4USER=account
  export P4CLIENT=local p4 workspace
  
  #bashrc
  source  p4config

执行完这一步，你应该就可以用 p4 login 命令登录了 perforce 服务器了。

#### 2. 代码管理

(1). checkout 代码：执行 git p4 clone Code_on_P4...@all localCode。
这个命令会把 p4 服务器上的代码检出到本地，如果不加 "...@all" 的话，只会检出最新版本。历史记录不会检出。
加上则会把该目录的所有历史记录检出并转成 git 的 log 形式。

(2). 检出完成后，就可以在本地用git管理代码。各种增删改....，然后用 git commit 提交到本地。

(3). 修改提交：执行 git p4 submit [branch]。
改命令把目前在git中新添加的提交上传到 perforce 上，执行完该命令后，会弹出一个编辑界面，让用户编辑需要提交的内容。
编辑完成后，保存就可。
可以通过[branch]选项指定要提交那个branch的内容到p4上。

OK，就是这样。
