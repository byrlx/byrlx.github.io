---
layout: default
title: Android logd功能
---

{{page.title}}
======================

#### 一，简介

Android Log系统在 L 版本有了很大的改动。通过在user space引入以叫做logd的机制来代替目前KitKat及之前版本Kernel 层的Logger 设备的实现。Logd代码的相关位置在
system/core/logd目录.在Android代码的git提交记录上,关于logd的信息
有一句话.

    logd: initial checkin.

    * Create a new userspace log daemon for handling logging messages.

logd的全部代码可以看[这里](https://android.googlesource.com/platform/system/core/+/882f856668331488d9bbaec429de7aac5d7978c9/logd)

#### 二，在系统中的位置

在 rootdir/init.rc 文件中，增加了开启logd service的相关代码。
从这段代码可以看到，系统启动时，init会启动一个叫做logd的service，
同时会建立三个socket。有趣的是，建立的这三个socket分别使用了三种
不同类型的type，我猜测作者之所以要这么做，是跟这三个socket在logd中
的不同作用有关，后面的内容会介绍。

最后一段代码猜测跟selinux机制相关。（待补充）

    service logd /system/bin/logd
        class main
        socket logd stream 0666 logd logd 
        socket logdr seqpacket 0666 logd logd 
        socket logdw dgram 0222 logd logd 
        seclabel u:r:logd:s0
        
在Kitkat
            
在logd的main()函数中，通过启动三个相应的线程来“读”、“写”，“控制”上面的三个socekt。
这就是logd机制的一个核心框架。具体代码如下。
    
    // LogReader listens on /dev/socket/logdr. When a client
    // connects, log entries in the LogBuffer are written to the client.
    
    LogReader *reader = new LogReader(logBuf);
    if (reader->startListener()) {
        exit(1);
    }
    
    // LogListener listens on /dev/socket/logdw for client
    // initiated log messages. New log entries are added to LogBuffer
    // and LogReader is notified to send updates to connected clients.
    
    LogListener *swl = new LogListener(logBuf, reader);
    if (swl->startListener()) {
        exit(1);
    }
    
    // Command listener listens on /dev/socket/logd for incoming logd
    // administrative commands.
    
    CommandListener *cl = new CommandListener(logBuf, reader, swl);
    if (cl->startListener()) {
        exit(1);
    }
    
#### 三，使用的libsysutil基类

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
