---
layout: default
title: LDK笔记:list_head
---

{{page.title}}
-------------

LDK一书全名是<Linux Kernel Development>, 作者是Kernel大婶Robert Love,目前在google工作,同时作者设计了Android系统许多的机制,例如Log机制,Ashmem等机制.本文是该书第三版第六章"内核数据结构"的读书笔记. 主要学习 list_head 的机制和实现.

学过数据结构的人对链接肯定是非常熟悉,无论是在大学课程的学习或工作中都有实现链表的经历.在实现基本的结构体时,通常会在结构体中设计一个指向该结构体的指针变量,把该类型的结构体变量串起来,这就是链表.例如下面的code:
这段代码无需多讲,学过编程的人应该一眼就能看懂.

	struct node{
		int member;
		struct node *next;
		struct node *prev;
	}

与通常的链表实现不同,linux在2.1版本中引入了官方的通用链表机制,任何类型的结构体都可以使用该机制实现自己的链表.这就是通用的思想仍.它不像上面的code那样,每次定义一个结构体,都必须定义该类型的指针(next,prev)来实现链表.Linux链表的思想是把通用链表作为成员变量插入到结构体中.

该链表的定义在"include/linux/type.h" (该文使用的kernel版本为linux-3.9.6)
	
	struct list_head {
		struct list_head *next, *prev;
	};
	
代码实现很简单,就是一个双向的结构体实现,与平常的结构体不同的是它没有任何的实质成员变量(int, char....). 这里主要看它的实现. 可以看一下内核中的代码是怎么使用该结构体的.
	
	struct task_struct {
	
		.....

		struct list_head tasks;

		....
	}

这是list_head在内核核心结构task_struct中的使用,因为这个机构体无比庞大,这里略过了大部分的代码. 

OK,已经看到了内核是怎样使用list_head的,按照linux的思想,可以通过这个tasks变量的next,prev来遍历所有的task_struct变量,那么,这里最大的一个问题是:怎么根据tasks来获得包含它的结构体? 

例如,理论上讲,我们使用tasks->next应该可以得到下一个task_struct成员,但是按照程序语言的语法,tasks->next只能得到下一关list_head变量,哪要怎么根据这个变量获得相应的结构体呢?使用内核提供的container_of()宏可以解决这个问题. 该宏的代码在"include/linux/kernel.h"中.

	/**
	 * container_of - cast a member of a structure out to the containing structure
	 * @ptr:	the pointer to the member.
	 * @type:	the type of the container struct this is embedded in.
	 * @member:	the name of the member within the struct.
	 *
	 */
	#define container_of(ptr, type, member) ({			\
		const typeof( ((type *)0)->member ) *__mptr = (ptr);	\
		(type *)( (char *)__mptr - offsetof(type,member) );})
	
例如这里有一个task_struct成员lx_task,那么通过container_of(lx_task->tasks, task_struct, tasks)即可以得到lx_task.通过分析代码可以得到具体的实现过程.

在编译内核的时候,每个结构体的各个成员在该结构体中的偏移量就被固定下来.例如上例中假设tasks的偏移为offset, lx_task->tasks(即遍历时得到的list_head指针)为A,则lx_task的地址为"A-offset", 程序中的两行代码就是实现这个公式.
		const typeof( ((type *)0)->member ) *__mptr = (ptr);
这行代码定义了一个member类型(在本文中可以理解为list_head)的指针__mptr,并把真实的指针ptr赋值给它.这样__mptr与ptr指向相同的内容.
		(type *)( (char *)__mptr - offsetof(type,member) )
这行代码生成一个type类型(这里可以理解为task_struct)的指针,通过当前list_head变量指针的地址减去offset值即可以得到包含该成员的变量地址. offsetof()的定义如下. 通过该宏可以得到成员在结构体中的offset值.

	#undef offsetof
	#ifdef __compiler_offsetof
	#define offsetof(TYPE,MEMBER) __compiler_offsetof(TYPE,MEMBER)
	#else
	#define offsetof(TYPE, MEMBER) ((size_t) &((TYPE *)0)->MEMBER)
	#endif
	#endif
