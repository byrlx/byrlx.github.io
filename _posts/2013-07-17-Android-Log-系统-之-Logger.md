---
layout: default
title: Android Log 系统之 Logger
---

{{page.title}}
----------------------------------

中 [logcat](http://byrlx.github.io/2013/07/10/Android-Log-%E7%B3%BB%E7%BB%9F%E4%B9%8B-logcat.html) 和 [liblog](http://byrlx.github.io/2013/07/13/Android-Log-%E7%B3%BB%E7%BB%9F%E4%B9%8B-liblog.html) 这两篇文章,讲到了android系统中如何读log和写log. 那么,log存放的位置在哪里? 本文就介绍一下android 系统中存放log的地方: logger device.

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

对于之前介绍的 [logcat](http://byrlx.github.io/2013/07/10/Android-Log-%E7%B3%BB%E7%BB%9F%E4%B9%8B-logcat.html) 和 [liblog](http://byrlx.github.io/2013/07/13/Android-Log-%E7%B3%BB%E7%BB%9F%E4%B9%8B-liblog.html), 讲到都是通过read()/write()函数来读写log, read/write的实现则对应到driver层注册到file system的 fops.

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

通过传入的inode节点的次设备号从log_list链表中找到对应的logger device的结构体. 接着会判断打开方式,如果打开方式中包含"read"(例如logcat)的话,会分配一个logger_read结构体被赋值给file的private_data变量,否则file的private_data变量直接指向logger.

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
	
r_all部分目前还不太理解,以后再补充.....

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
