---
layout: default
title: Android L Log系统变化(2): logd介绍
---

{{page.title}}
-------------------

#### 一，简介

在之前介绍log系统的文章中提到, Android上所有的最后都会写到 Kernel 层的 logger 虚拟设备中,
这些其实就是一些内存缓冲. 在 L 版本上，存log的机制有了变化，android系统在user space引入了一个
叫做logd的机制，来替换目前使用的logger机制，这样实现了log系统与linux内核的更进一步剥离。

在Android代码的git提交记录上,关于logd的信息有一句话.

    logd: initial checkin.

    * Create a new userspace log daemon for handling logging messages.

logd的全部代码可以看[这里](https://android.googlesource.com/platform/system/core/+/master/logd)

#### 二，logd架构

logd主要通过socket的方式来接受/发送log，同时也可以通过socket
执行用户的一些命令（如清空buffer，查看统计信息等）。

logd在开机被init进程启动，然后成为一个守护进程。
下面是 rootdir/init.rc 文件中logd启动的相关代码。
可以看到，系统启动时，init会执行logd命令来启动logd服务，
同时会建立三个socket。有趣的是，建立的这三个socket分别使用了三种
不同类型的type，我猜测作者之所以要这么做，是跟这三个socket在logd中
的不同作用有关，后面的内容会介绍。
最后一行设置了logd的selinux配置。

    service logd /system/bin/logd
        class main
        socket logd stream 0666 logd logd 
        socket logdr seqpacket 0666 logd logd 
        socket logdw dgram 0222 logd logd 
        seclabel u:r:logd:s0
        
logdw：所有的使用android log api生成的log都会通过该socket写入到logd
的buffer中；
logdr：logcat通过这个socket将logd buffer中的log读出；
logd：对logd buffer的控制命令，主要对log buffer做一些操作或者获取相关配置。
    
#### 三：使用的libsysutil基类

logd的代码是用C++撰写，socket部分的code使用了libsysutil目录下的socket相关的基类，
体现了面向对象的思想。
 
logd的全部代码可以看[这里](https://android.googlesource.com/platform/system/core/+/master/logd)

#### 二，logd架构

logd主要通过socket的方式来接受/发送log，同时也可以通过socket
执行用户的一些命令（如清空buffer，查看统计信息等）。

logd在开机被init进程启动，然后成为一个守护进程。
下面是 rootdir/init.rc 文件中logd启动的相关代码。
可以看到，系统启动时，init会执行logd命令来启动logd服务，
同时会建立三个socket。有趣的是，建立的这三个socket分别使用了三种
不同类型的type，我猜测作者之所以要这么做，是跟这三个socket在logd中
的不同作用有关，后面的内容会介绍。
最后一行设置了logd的selinux配置。

    service logd /system/bin/logd
        class main
        socket logd stream 0666 logd logd 
        socket logdr seqpacket 0666 logd logd 
        socket logdw dgram 0222 logd logd 
        seclabel u:r:logd:s0
        
logdw：所有的使用android log api生成的log都会通过该socket写入到logd
的buffer中；
logdr：logcat通过这个socket将logd buffer中的log读出；
logd：对logd buffer的控制命令，主要对log buffer做一些操作或者获取相关配置。
    
#### 三：使用的libsysutil基类

logd的代码是用C++撰写，socket部分的code使用了libsysutil目录下的socket相关的基类，
体现了面向对象的思想。
 
logd的全部代码可以看[这里](https://android.googlesource.com/platform/system/core/+/master/logd)

#### 二，logd架构

logd主要通过socket的方式来接受/发送log，同时也可以通过socket
执行用户的一些命令（如清空buffer，查看统计信息等）。

logd在开机被init进程启动，然后成为一个守护进程。
下面是 rootdir/init.rc 文件中logd启动的相关代码。
可以看到，系统启动时，init会执行logd命令来启动logd服务，
同时会建立三个socket。有趣的是，建立的这三个socket分别使用了三种
不同类型的type，我猜测作者之所以要这么做，是跟这三个socket在logd中
的不同作用有关，后面的内容会介绍。
最后一行设置了logd的selinux配置。

    service logd /system/bin/logd
        class main
        socket logd stream 0666 logd logd 
        socket logdr seqpacket 0666 logd logd 
        socket logdw dgram 0222 logd logd 
        seclabel u:r:logd:s0
        
logdw：所有的使用android log api生成的log都会通过该socket写入到logd
的buffer中；
logdr：logcat通过这个socket将logd buffer中的log读出；
logd：对logd buffer的控制命令，主要对log buffer做一些操作或者获取相关配置。
    
#### 三：使用的libsysutil基类

logd的代码是用C++撰写，socket部分的code使用了libsysutil目录下的socket相关的基类，
体现了面向对象的思想。
 
logd的全部代码可以看[这里](https://android.googlesource.com/platform/system/core/+/master/logd)

#### 二，logd架构

logd主要通过socket的方式来接受/发送log，同时也可以通过socket
执行用户的一些命令（如清空buffer，查看统计信息等）。

logd在开机被init进程启动，然后成为一个守护进程。
下面是 rootdir/init.rc 文件中logd启动的相关代码。
可以看到，系统启动时，init会执行logd命令来启动logd服务，
同时会建立三个socket。有趣的是，建立的这三个socket分别使用了三种
不同类型的type，我猜测作者之所以要这么做，是跟这三个socket在logd中
的不同作用有关，后面的内容会介绍。
最后一行设置了logd的selinux配置。

    service logd /system/bin/logd
        class main
        socket logd stream 0666 logd logd 
        socket logdr seqpacket 0666 logd logd 
        socket logdw dgram 0222 logd logd 
        seclabel u:r:logd:s0
        
logdw：所有的使用android log api生成的log都会通过该socket写入到logd
的buffer中；
logdr：logcat通过这个socket将logd buffer中的log读出；
logd：对logd buffer的控制命令，主要对log buffer做一些操作或者获取相关配置。
    
#### 三：使用的libsysutil基类

logd的代码是用C++撰写，socket部分的code使用了libsysutil目录下的socket相关的基类，
体现了面向对象的思想。
 
logd的全部代码可以看[这里](https://android.googlesource.com/platform/system/core/+/master/logd)

#### 二，logd架构

logd主要通过socket的方式来接受/发送log，同时也可以通过socket
执行用户的一些命令（如清空buffer，查看统计信息等）。

logd在开机被init进程启动，然后成为一个守护进程。
下面是 rootdir/init.rc 文件中logd启动的相关代码。
可以看到，系统启动时，init会执行logd命令来启动logd服务，
同时会建立三个socket。有趣的是，建立的这三个socket分别使用了三种
不同类型的type，我猜测作者之所以要这么做，是跟这三个socket在logd中
的不同作用有关，后面的内容会介绍。
最后一行设置了logd的selinux配置。

    service logd /system/bin/logd
        class main
        socket logd stream 0666 logd logd 
        socket logdr seqpacket 0666 logd logd 
        socket logdw dgram 0222 logd logd 
        seclabel u:r:logd:s0
        
logdw：所有的使用android log api生成的log都会通过该socket写入到logd
的buffer中；
logdr：logcat通过这个socket将logd buffer中的log读出；
logd：对logd buffer的控制命令，主要对log buffer做一些操作或者获取相关配置。
    
#### 三：使用的libsysutil基类

logd的代码是用C++撰写，socket部分的code使用了libsysutil目录下的socket相关的基类，
体现了面向对象的思想。
 
socket基类相关代码可以看[这里](https://android.googlesource.com/platform/system/core/+/master/libsysutils)

##### 1. SocketListener

在上一节讲到，logd会在main()函数中启动三个线程来监控socket，从代码看出，
这三个线程都是通过调用类的startListener()函数实现的。这里就用到了libsysutil的
Socket相关的组件，其中最重要的部分就是SocketListener，
因为上述logd实现的类都直接或间接继承自SocketListener类。

- 该类主要用于监听socket,可以通过传入"类名"或fd来初始化一个该类对象,
   用于监控相应的socket.该类是一个抽象基类,因为其成员函数
   onDataAvailable()是纯虚函数.
- 该类的构造函数都通过调用init()成员函数来初始化各成员变量,主要包
   括:mSock,mListen代表是否要listen mSock这个fd.同时该类还有一个
   SocketClient的list,用来存放mSock上的连接(如果mListen为false,则该
   list用来存放mSock自己).
- 析构函数:关掉socket,释放每个client.
- startListener()函数工作:a,获得socketfd; b,mListen为真,监听mSock,否
   则,使用mSock生成一个SocketClient对象插入到mClients里.启动线程,执行
   runListener()函数.
- stopListener():关掉PIPE,socket,释放clients.同时pthread_join()上面的
   线程.
- runListener()函数是线程的主体,该函数通过一个while()循环来监听所有的
   fd.主要分两种情况:
   a, mListen为true,则mSock可以被连接,每个连接都被初始化为一个
   SocketClient对象插入到类的mClients中,同时该对象的socket fd也会被
   select监听.
   b, mListen为false,则只监听mClients里的对象fd.
   对于mClients里的每个对象,如果有数据可读时,则将这些对象放入一个
   pendingList中,并增加该对象的引用计数.接下来,对pendingList中的每个可
   读对象,调用onDataAvailble()函数.该函数是一个纯虚函数,每个子类都必须
   实现.
- release()函数:如果mListen为真,client从mClinets里删除.
- sendBroadcaset()函数:向mClients里的每个项发广播.
- runOnEachSocket(),接收一个SocektClientCommand的对象,通过该对象对
   mClients的每个项运行runSocketCommand()命令.

##### 2，SocketClient

- 构造函数:接收的参数一般为socketfd,owned(在SocketListener中,连接到
   listen socket的client的owned都为true,而mListen为false时,用当前
   socket创建的对象owned为false),然后调用init()函数.
- init()函数工作:
   a,根据参数初始化类的成员变量.
   b,使用getsockopt()获取客户端进程的权限属性,这些属性包括:pid,uid,gid
   等.
- sendMsg/Data()函数集:这些函数最后都会调到sendDataLockedv().
- sendDataLockedv():先将SIGPIPE设成SIG_IGN,然后向socket成员写入vector
   变量.
- incRef()/decRef():增加/减少引用计数,如果减少到0,调用delete this删除
   当前对象.

##### 3，FrameworkListener

- 继承自SocketListener，有一个FrameworkCommand类型的list作为成员变量。
- 构造函数会将mListener设为true，表示会监听这个socket。
- registerCmd(cmd):将一个FrameworkCommand对象插入到list中.
- onDataAvailable(cli):从client中读取数据,读取的数据可能有多条,每一条
   以'\0'结尾,但是,实际上这些数据组成一条完整的命令(数据可能是命令+参
   数),对每一条调用dispatchCommand()命令.
- dispatchCommand(cli,data):解析命令行data，查找当前的mCommands是否有
   对应的命令（argv\[0\]),如果有,则执行runCommand()函数.

##### 4，FrameworkCommand

- 该类用来存放一个具体的command对象,runCommand()是一个纯虚函数,因此应
   该被所有子类实现.
