---
layout: default
title: 从 read() 函数看kernel的cache机制
---

{{page.title}}
-----------------------------

本文主要分析Linux kernel的read()流程，从该流程看一下内核中cache机制的原理和实现。

userspace在调用read(fd, buf, size)时，会透过系统调用call到sys_read(),然后会call到VFS&EXT3层的函数vsf_read(file,buf,size,pos)。
此处file是一个struct file× 类型的指针，跟fd是一一对应的关系。

在该函数里会调用file的f_op->read()函数，通常情况下，该指针指向do_sync_read(file, buf, size, pos)。
在该函数中会调用file的另一个函数f_op->aio_read()函数，该指针指向generic_file_aio_read(iocb, iov, size, pos)。
该函数会调用do_generic_file_read(file, pos, desc, actor)。
最好调用find_get_page(mapping, offset)进去page cache层找到需要的page。

#### page cache

page cache指在内存中存放一些page页面，提高系统访问页面的速度。
（A "transparent" buffer of disk-backed pages kept in RAM for quicker access）。
这些page以tree的形式进行管理，通过一个mapping和一个offset能唯一定位tree中page。
就是上面最后find_get_page()做的工作。

#### address space

在read_get_page(mapping, offset)中，mapping是一个struct address_space结构体变量。

这里介绍几个成员变量：host指向文件的inode，page_tree指向用于管理page cache的radix tree。
在do_generic_file_read(file, pos, desc, actor)中，文件是以byte为单位偏移，
但 file 在page cache中是以page为单位进行管理，所以offset 传到page cache时需要做转换。
