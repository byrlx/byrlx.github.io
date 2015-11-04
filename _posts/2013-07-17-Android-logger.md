---
layout: post
title: Android Logger
tags: [Android, Log]
---

[logcat](../Android-logcat/) 和 [liblog](../Android-liblog/) 这两篇文章,讲到了android系统中如何读log和写log. 那么,log存放的位置在哪里? 本文就介绍一下android 系统中存放log的地方: logger device.

Android 在 kernel 层提供了四个虚拟的device 设备,用于存放log. 可以通过输入 `adb shell ls /dev/log/` 来查看系统的虚拟logger 设备. 这些设备是在系统启动的时候以内核模块的方式初始化.

	device_initcall(logger_init);

	static int __init logger_init(void)
	{
		int ret;
	
		ret = create_log(LOGGER_LOG_MAIN, 256*1024);
		if (unlikely(ret))
			goto out;
	
		ret = create_log(LOGGER_LOG_EVENTS, 256*1024);
		if (unlikely(ret))
			goto out;
	
		ret = create_log(LOGGER_LOG_RADIO, 256*1024);
		if (unlikely(ret))
			goto out;
	
		ret = create_log(LOGGER_LOG_SYSTEM, 256*1024);
		if (unlikely(ret))
			goto out;
	
	out:
		return ret;
	}
	
模块初始话函数通过create_log()生成四个device,并指定了每个device的大小.

	static int __init create_log(char *log_name, int size)
	{
		int ret = 0;
		struct logger_log *log;
		unsigned char *buffer;
	
		buffer = vmalloc(size);
		if (buffer == NULL)
			return -ENOMEM;
	
		log = kzalloc(sizeof(struct logger_log), GFP_KERNEL);
		if (log == NULL) {
			ret = -ENOMEM;
			goto out_free_buffer;
		}
		log->buffer = buffer;
	
		log->misc.minor = MISC_DYNAMIC_MINOR;
		log->misc.name = kstrdup(log_name, GFP_KERNEL);
		if (log->misc.name == NULL) {
			ret = -ENOMEM;
			goto out_free_log;
		}
	
		log->misc.fops = &logger_fops;
		log->misc.parent = NULL;
	
		init_waitqueue_head(&log->wq);
		INIT_LIST_HEAD(&log->readers);
		mutex_init(&log->mutex);
		log->w_off = 0;
		log->head = 0;
		log->size = size;
	
		INIT_LIST_HEAD(&log->logs);
		list_add_tail(&log->logs, &log_list);
	
		/* finally, initialize the misc device for this log */
		ret = misc_register(&log->misc);
		if (unlikely(ret)) {
			pr_err("failed to register misc device for log '%s'!\n",
					log->misc.name);
			goto out_free_log;
		}
	
		pr_info("created %luK log '%s'\n",
			(unsigned long) log->size >> 10, log->misc.name);
	
		return 0;
	
	out_free_log:
		kfree(log);
	
	out_free_buffer:
		vfree(buffer);
		return ret;
	}

对于每一个logger device,都对应一个核心的结构体: struct logger_log. create_log()函数的作用就是分配一个logger_log,初始化其变量,并通过misc_register()注册为misc设备.

对于之前介绍的 [logcat](../Android-logcat/) 和 [liblog](../Android-liblog/), 讲到都是通过read()/write()函数来读写log, read/write的实现则对应到driver层注册到file system的 fops.

	log->misc.fops = &logger_fops;
	
	static const struct file_operations logger_fops = {
		.owner = THIS_MODULE,
		.read = logger_read,
		.aio_write = logger_aio_write,
		.poll = logger_poll,
		.unlocked_ioctl = logger_ioctl,
		.compat_ioctl = logger_ioctl,
		.open = logger_open,
		.release = logger_release,
	};

#### 打开Logger设备

在应用层通过调用open("/dev/log/main",O_RDWR)的方式可以打开一个logger设备,对应的kernel 层的实现是logger_open.

	/* logger_open() */
	log = get_log_from_minor(MINOR(inode->i_rdev));
	if (!log)
		return -ENODEV;

	if (file->f_mode & FMODE_READ) {
		struct logger_reader *reader;

		reader = kmalloc(sizeof(struct logger_reader), GFP_KERNEL);
		if (!reader)
			return -ENOMEM;

		reader->log = log;
		reader->r_ver = 1;
		reader->r_all = in_egroup_p(inode->i_gid) ||
			capable(CAP_SYSLOG);

		INIT_LIST_HEAD(&reader->list);

		mutex_lock(&log->mutex);
		reader->r_off = log->head;
		list_add_tail(&reader->list, &log->readers);
		mutex_unlock(&log->mutex);

		file->private_data = reader;
	} else
		file->private_data = log;

通过传入的inode节点的次设备号从log_list链表中找到对应的logger device的结构体. 接着会判断打开方式,如果打开方式中包含"read"(例如logcat)的话,会分配一个logger_read结构体被赋值给file的private_data变量,同时会把reader的读开始位置设为logger buffer的head位置(也就是从头开始读),然后把reader加入到logger的reader链表中.否则file的private_data变量直接指向logger.

#### 读logger

read()函数对应logger_read.

	.read = logger_read,

	static ssize_t logger_read(struct file *file, char __user *buf,
				   size_t count, loff_t *pos)
	{
		struct logger_reader *reader = file->private_data;
		struct logger_log *log = reader->log;
		ssize_t ret;
		DEFINE_WAIT(wait);
	
	start:
		while (1) {
			mutex_lock(&log->mutex);
	
			prepare_to_wait(&log->wq, &wait, TASK_INTERRUPTIBLE);
	
			ret = (log->w_off == reader->r_off);
			mutex_unlock(&log->mutex);
			if (!ret)
				break;
	
			if (file->f_flags & O_NONBLOCK) {
				ret = -EAGAIN;
				break;
			}
	
			if (signal_pending(current)) {
				ret = -EINTR;
				break;
			}
	
			schedule();
		}
	
		finish_wait(&log->wq, &wait);
		if (ret)
			return ret;
	
首先程序会在一个while循环中做一些判断:如果w_off不等于r_off,表明目前logger中有log可读,跳出循环.否则,如果设备以非阻塞的方式打开,直接返回 -EAGAIN 的错误. 如果程序被信号打断,则返回 -EINTR. 如果这些条件都不满足,表示目前没有log可读,调用schedule()让出cpu.

		/*logger_read()*/
		mutex_lock(&log->mutex);
	
		if (!reader->r_all)
			reader->r_off = get_next_entry_by_uid(log,
				reader->r_off, current_euid());
	
		/* is there still something to read or did we race? */
		if (unlikely(log->w_off == reader->r_off)) {
			mutex_unlock(&log->mutex);
			goto start;
		}
	
r_all部分目前还不太理解,以后再补充.....(从代码来看,这个变量应该是与reader的权限有关,通过这个变量可以控制该reader是否有权限去读所有的log, 如果为0,表明reader没有该权限,只能读自己进程euid相等的log)

		/*logger_read()*/
		ret = get_user_hdr_len(reader->r_ver) +
			get_entry_msg_len(log, reader->r_off);
		if (count < ret) {
			ret = -EINVAL;
			goto out;
		}
	
通过get_user_hdr_len()及get_entry_msg_len()获取entry的header长度和entry长度,加起来就是一条log的长度.

	static size_t get_user_hdr_len(int ver)
	{
		if (ver < 2)
			return sizeof(struct user_logger_entry_compat);
		else
			return sizeof(struct logger_entry);
	}

该函数会根据传入的reader成员r_ver的值来决定返回哪个长度的entry header值,因为在logger_open中该值被设定为1, 故该函数的返回值为 user_logger_entry_compat 的长度. 接着读取log entry的长度.

	static __u32 get_entry_msg_len(struct logger_log *log, size_t off)
	{
		struct logger_entry scratch;
		struct logger_entry *entry;
	
		entry = get_entry_header(log, off, &scratch);
		return entry->len;
	}


	static struct logger_entry *get_entry_header(struct logger_log *log,
			size_t off, struct logger_entry *scratch)
	{
		size_t len = min(sizeof(struct logger_entry), log->size - off);
		if (len != sizeof(struct logger_entry)) {
			memcpy(((void *) scratch), log->buffer + off, len);
			memcpy(((void *) scratch) + len, log->buffer,
				sizeof(struct logger_entry) - len);
			return scratch;
		}
	
		return (struct logger_entry *) (log->buffer + off);
	}

因为每个logger device的size都是固定大小,而系统中的log量要远远大于该size,故logger device都是采用 ring buffer的方式存放log. 这样就可能出现这个的情况,一条log的一部分在buffer尾部,而另一部分在buffer头部,所以每次从buffer读log都要考虑这种情况. 获得entry之后,通过entry的变量len就可以知道msg的长度. 调用 do_read_log_to_user()将entry+msg写到user的buf中.

		ret = do_read_log_to_user(log, reader, buf, ret);

#### Log write

之前有讲,user space在写log的流程最后调用到了write()函数,对应到driver层的实现为 logger_aio_write(). 让我们一段一段的分析这个函数的实现.

	static ssize_t logger_aio_write(struct kiocb *iocb, const struct iovec *iov,
				 unsigned long nr_segs, loff_t ppos)
	{
		struct logger_log *log = file_get_log(iocb->ki_filp);
		size_t orig = log->w_off;
		struct logger_entry header;
		struct timespec now;
		ssize_t ret = 0;

首先是调用file_get_log()函数获得这个文件结构体对应的logger设备. 在打开设备的代码中有讲,file结构体的private_data变量会存放两个值之一:logger或reader,所以这里会判断文件是否以FMODE_READ的方式打开,如果是,则private_data为reader,需要去reader中找logger,否则直接返回private_data.
	
	static inline struct logger_log *file_get_log(struct file *file)
	{
		if (file->f_mode & FMODE_READ) {
			struct logger_reader *reader = file->private_data;
			return reader->log;
		} else
			return file->private_data;
	}
	
下面的代码通过系统参数初始化log entry的header.
		now = current_kernel_time();
	
		header.pid = current->tgid;
		header.tid = current->pid;
		header.sec = now.tv_sec;
		header.nsec = now.tv_nsec;
		header.euid = current_euid();
		header.len = min_t(size_t, iocb->ki_left, LOGGER_ENTRY_MAX_PAYLOAD);
		header.hdr_size = sizeof(struct logger_entry);
	
		/* null writes succeed, return zero */
		if (unlikely(!header.len))
			return 0;
	
		mutex_lock(&log->mutex);
	
接下来调用fix_up_readers()函数,通过传入本次log的长度对该logger设备的readers进行修正.
		/*
		 * Fix up any readers, pulling them forward to the first readable
		 * entry after (what will be) the new write offset. We do this now
		 * because if we partially fail, we can end up with clobbered log
		 * entries that encroach on readable buffer.
		 */
		fix_up_readers(log, sizeof(struct logger_entry) + header.len);

	static void fix_up_readers(struct logger_log *log, size_t len)
	{
		size_t old = log->w_off;
		size_t new = logger_offset(log, old + len);
		struct logger_reader *reader;
	
		if (is_between(old, new, log->head))
			log->head = get_next_entry(log, log->head, len);
	
		list_for_each_entry(reader, &log->readers, list)
			if (is_between(old, new, reader->r_off))
				reader->r_off = get_next_entry(log, reader->r_off, len);
	}

	static size_t get_next_entry(struct logger_log *log, size_t off, size_t len)
	{
		size_t count = 0;
	
		do {
			size_t nr = sizeof(struct logger_entry) +
				get_entry_msg_len(log, off);
			off = logger_offset(log, off + nr);
			count += nr;
		} while (count < len);
	
		return off;
	}
为什么要对reader进行修正?前面有讲过,logger buffer的size是固定的,系统采用ring buffer的方式写log,那么就会出现这样的情况,最新的logger会有机会覆盖前面的一条log,那么在这种情况下,对于reader来说,r_off这个参数就是无效的,因为下一条log(或者后面几条log)已经不存在了.

get_next_entry()的实现不难理解,因为新加入的log长度为len,即寻找从r_off+len位置之后的第一条有效log.

接下来就是真正把log的内容写入buffer
	
		do_write_log(log, &header, sizeof(struct logger_entry));
	
		while (nr_segs-- > 0) {
			size_t len;
			ssize_t nr;
	
			/* figure out how much of this vector we can keep */
			len = min_t(size_t, iov->iov_len, header.len - ret);
	
			/* write out this segment's payload */
			nr = do_write_log_from_user(log, iov->iov_base, len);
			if (unlikely(nr < 0)) {
				log->w_off = orig;
				mutex_unlock(&log->mutex);
				return nr;
			}
	
			iov++;
			ret += nr;
		}
	
		mutex_unlock(&log->mutex);
	
		/* wake up any blocked readers */
		wake_up_interruptible(&log->wq);
	
		return ret;
	}

首先会调用do_write_log()把header先写入buffer,这里直接调用memcpy(),header有可能被写到buffer的尾部和首部(ring buffer). 然后就是把user space传入的iovec数组的内容依次写入buffer. 如果写失败,会直接把logger的w_off位置roll back会之前的值.

#### logger_poll

在logcat的实现中曾讲到,logcat在打开logger设备后,会调用select()函数监控该logger设备,如果函数返回,表明有log可读,接下来就会调用read()读log.这里select对应的driver层函数就是logger_poll()
	
	static unsigned int logger_poll(struct file *file, poll_table *wait)
	{
		struct logger_reader *reader;
		struct logger_log *log;
		unsigned int ret = POLLOUT | POLLWRNORM;
	
		if (!(file->f_mode & FMODE_READ))
			return ret;
	
		reader = file->private_data;
		log = reader->log;
	
		poll_wait(file, &log->wq, wait);
	
		mutex_lock(&log->mutex);
		if (!reader->r_all)
			reader->r_off = get_next_entry_by_uid(log,
				reader->r_off, current_euid());
	
		if (log->w_off != reader->r_off)
			ret |= POLLIN | POLLRDNORM;
		mutex_unlock(&log->mutex);
	
		return ret;
	}

函数首先会判断是否以read的方式打开设备,如果不是,直接返回.(因为select()一般对应读操作,如果不读那么select()就没什么意义了).判断log是否可读的唯一条件就是w_off是否等于r_off.

OK,logger设备暂时就写到这里,以后有新的理解会继续补充.