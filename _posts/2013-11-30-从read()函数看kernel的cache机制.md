---
layout: post
title: 从 read() 函数看kernel的cache机制
category: Others
tag: [C, Linux]
description: [Cache memchanism of linux kernel]
---

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

	struct address_space {
		struct inode		*host;		/* owner: inode, block_device */
		struct radix_tree_root	page_tree;	/* radix tree of all pages */
		spinlock_t		tree_lock;	/* and lock protecting it */
		unsigned int		i_mmap_writable;/* count VM_SHARED mappings */
		struct rb_root		i_mmap;		/* tree of private and shared mappings */
		struct list_head	i_mmap_nonlinear;/*list VM_NONLINEAR mappings */
		struct mutex		i_mmap_mutex;	/* protect tree, count, list */
		/* Protected by tree_lock together with the radix tree */
		unsigned long		nrpages;	/* number of total pages */
		pgoff_t			writeback_index;/* writeback starts here */
		const struct address_space_operations *a_ops;	/* methods */
		unsigned long		flags;		/* error bits/gfp mask */
		struct backing_dev_info *backing_dev_info; /* device readahead, etc */
		spinlock_t		private_lock;	/* for use by the address_space */
		struct list_head	private_list;	/* ditto */
		void			*private_data;	/* ditto */
	} __attribute__((aligned(sizeof(long))));

这里介绍几个成员变量：host指向文件的inode，page_tree指向用于管理page cache的radix tree。
在do_generic_file_read(file, pos, desc, actor)中，文件是以byte为单位偏移，
但 file 在page cache中是以page为单位进行管理，所以offset 传到page cache时需要做转换。
32位机器上，一个page为4K（2×12），所以只需要将byte地址右移12位即可得到page地址。

	index = *ppos >> PAGE_CACHE_SHIFT;

#### radix tree

首先来看下find_get_page()的代码实现,
	可以看到会调用radix_tree_lookup_slot()去查找给定的offset在radix tree中的位置。

	struct page *find_get_page(struct address_space *mapping, pgoff_t offset)
	{
		void **pagep;
		struct page *page;
	
		rcu_read_lock();
	repeat:
		page = NULL;
		pagep = radix_tree_lookup_slot(&mapping->page_tree, offset);
		if (pagep) {
			page = radix_tree_deref_slot(pagep);
			...
		}

radix tree 是内核的一个通用数据结构，它的使用方法与list_head很相似，
在内核中被广泛使用。这里我们就看一下radix_tree相关的一些知识。
