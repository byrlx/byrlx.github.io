---
layout: default
title: Android Log 系统之 Logcat
---

{{page.title}}
==============

这篇文章介绍android系统中录log的工具 logcat.

Android 系统提供了一整套的API供Java层和Native层的程序写log,以方便调试及在系统出问题的时候有据可查. 
而logcat是把这些抓log的工具,可以通过logcat把log显示到标准输出或文件中,同时还可以对log进行过滤. 设定log level及只读取指定module的log. logcat 的详细用法可以在手机中输入"logcat --help" 命令查看.

本文主要对logcat的源码进行分析,从main函数开始.从main函数开始遇到的第一个函数调用是.

    g_logformat = android_log_format_new();

看下这个函数的定义:
	
	/* android_log_format_new()*/
	AndroidLogFormat *android_log_format_new()
	{
	    AndroidLogFormat *p_ret;
	
	    p_ret = calloc(1, sizeof(AndroidLogFormat));
	
	    p_ret->global_pri = ANDROID_LOG_VERBOSE;
	    p_ret->format = FORMAT_BRIEF;
	
	    return p_ret;
	}
	
这个函数通过malloc生成一个 AndroidLogFormat 的结构体,并将结构体的成员变量 'global_pri' 和 'format' 设置.先省略这个结构体的实现,继续看main 函数的代码.

	/* main()*/
    if (argc == 2 && 0 == strcmp(argv[1], "--test")) {
        logprint_run_tests();
        exit(0);
    }

#### test 参数

如果logcat只有一个参数"--test",则执行logprint_run_tests()函数,从代码来看,这个函数主要是测试logcat的功能的.

	/* logprint_run_tests()*/
    p_format = android_log_format_new();
    fprintf(stderr, "running tests\n");
    tag = "random";
    android_log_addFilterRule(p_format,"*:i");

这个函数开始也call了一次 android_log_format_new()分配了一个结构体.并设置了tag变量,tag是每个module在打log时都需要设置一个tag,可以通过tag用来标志是该module输出的log. 接着call函数 android_log_addFilterRule(), 设置logcat的过滤机制.

	/* android_log_addFilterRule() */
	android_LogPriority pri = ANDROID_LOG_DEFAULT;
	tagNameLength = strcspn(filterExpression, ":");
    if(filterExpression[tagNameLength] == ':') {
        pri = filterCharToPri(filterExpression[tagNameLength+1]);

        if (pri == ANDROID_LOG_UNKNOWN) {
            goto error;
        }
    }

该函数设置pri变量的值为 ANDROID_LOG_DEFAULT, 这个值被定义在一个enum中,如果log pririoty被设为 ANDROID_LOG_DEFAULT, 则表示输出所有等级的log.接着获得filter的tag的长度,根据前面的参数,"*:i"的返回结果是1, 接着调用filterCharToPri(),并传入参数"i"
. 这个函数把传入的字符形式的log level 转换为数字level,这些level和 ANDROID_LOG_DEFAULT一起定义在enum中.

    } else if (c == 'i') {
        pri = ANDROID_LOG_INFO;

	/* define */
	enum  {
	    ANDROID_LOG_UNKNOWN = 0,
	    ANDROID_LOG_DEFAULT,    /* only for SetMinPriority() */
	
	    ANDROID_LOG_VERBOSE,
	    ANDROID_LOG_DEBUG,
	    ANDROID_LOG_INFO,
	    ANDROID_LOG_WARN,
	    ANDROID_LOG_ERROR,
	    ANDROID_LOG_FATAL,
	
	    ANDROID_LOG_SILENT,     /* only for SetMinPriority(); must be last */
	
接下来判断是否有设置全局的log level,即传入的filter中是否包含"*:x"的字符串,如果是的话,就设置一个全局性的log level

	/* android_log_addFilterRule() */
    if(0 == strncmp("*", filterExpression, tagNameLength)) {
        if (pri == ANDROID_LOG_DEFAULT) {
            pri = ANDROID_LOG_DEBUG;
        }
        p_format->global_pri = pri;

这样,runtest()函数的filter设置就完成了,剩下都是一些基本的检查语句检查设置有没有成功.

	    assert (ANDROID_LOG_INFO == filterPriForTag(p_format, "random"));

这条语句检查tag "random"的priority是否是ANDROID_LOG_INFO,看下 filterPriForTag()函数实现

	static android_LogPriority filterPriForTag(
	        AndroidLogFormat *p_format, const char *tag)
	{
	    FilterInfo *p_curFilter;
	    for (p_curFilter = p_format->filters
	            ; p_curFilter != NULL
	            ; p_curFilter = p_curFilter->p_next
	    ) {
	        if (0 == strcmp(tag, p_curFilter->mTag)) {
	            if (p_curFilter->mPri == ANDROID_LOG_DEFAULT) {
	                return p_format->global_pri;
	            } else {
	                return p_curFilter->mPri;
	            }
	        }
	    }
	
	    return p_format->global_pri;
	}

这段code很直观,首先遍历p_format的filter,检查有没有设置tag的priority, 如果没有找到,就返回全局的log level. 还有另一个需要检查的地方

    assert(android_log_shouldPrintLine(p_format, tag, ANDROID_LOG_DEBUG) == 0);

在android中每条log都对应要一个priority,这个函数检查相应tag的这条log是否应该打印出来.
	
	int android_log_shouldPrintLine (
	        AndroidLogFormat *p_format, const char *tag, android_LogPriority pri)
	{
	    return pri >= filterPriForTag(p_format, tag);
	}

通过filterPriForTag()函数查找该tag的priority,然后跟传入的level做比较,判断是否需要打印该tag该level级别的log.

同时,可以通过 android_log_addFilterString()设定多个log filter.

    err = android_log_addFilterString(p_format, "*:s random:d ");

	int android_log_addFilterString(AndroidLogFormat *p_format,
	        const char *filterString)
	{
	    // Yes, I'm using strsep
	    while (NULL != (p_ret = strsep(&p_cur, " \t,"))) {
	        // ignore whitespace-only entries
	        if(p_ret[0] != '\0') {
	            err = android_log_addFilterRule(p_format, p_ret);
	        }
	    }
	......	
	}

android_log_addFilterString()会循环遍历传入的filter string,并将其添加到filter 链表中.
ok, "--test" 参数到这里就讲完了.

#### "-s" 参数

将全局的log level 设为 ANDROID_LOG_SILENT, 即不输出所有level的log

	android_log_addFilterRule(g_logformat, "*:s");

#### "-c" 参数

该参数可以将log device中的log删除.

	case 'c':
       clearLog = 1;
       mode = O_WRONLY;
    break;

        if (clearLog) {
            int ret;
            ret = android::clearLog(dev->fd);

看下clearLog函数

	static int clearLog(int logfd)
	{
	    return ioctl(logfd, LOGGER_FLUSH_LOG);
	}

该函数向driver层下发 LOGGER_FLUSH_LOG 命令,告诉logger device的driver将logger中的log清除,关于logger device的实现在后面会讲到.

#### "-d" "-t N" 参数

这两个参数都会将g_nonblock变量设为true,表示把logger里的log读完就会立刻退出,而不会等待新log的写入. 同时"-t"参数后面还要跟着一个值N,表示只读最近的N条log.

#### "-g" 参数

给driver发送LOGGER_GET_LOG_BUF_SIZE, 获得logger device的大小.

#### "-b device" 参数

指定要从哪个buffer中读log, "-b"可以使用多次,例如" -b main -b radio"

#### "-B" 参数

以二进制方式打印log(目前默认会对log进行解析,以字符串形式打印)

#### "-f file" 参数

将log 输出到指定文件 file

#### "-r size" 参数

设定rotate size大小,rotate size 的含义是每种log 最多只有 size 大小. 录满后旧log会被覆盖

#### "-n num" 参数

设定每种log最大的log file数量,每个file的大小为 rotate_size/num

#### "-v format" 参数

设定输出的log 格式

	err = setLogFormat (optarg);
	static int setLogFormat(const char * formatString)
	{
	    static AndroidLogPrintFormat format;
	
	    format = android_log_formatFromString(formatString);
	    android_log_setPrintFormat(g_logformat, format);

	    return 0;
	}

	AndroidLogPrintFormat android_log_formatFromString(const char * formatString)
	{
	    static AndroidLogPrintFormat format;
	
	    if (strcmp(formatString, "brief") == 0) format = FORMAT_BRIEF;
	    else if (strcmp(formatString, "process") == 0) format = FORMAT_PROCESS;
	    else if (strcmp(formatString, "tag") == 0) format = FORMAT_TAG;
	    else if (strcmp(formatString, "thread") == 0) format = FORMAT_THREAD;
	    else if (strcmp(formatString, "raw") == 0) format = FORMAT_RAW;
	    else if (strcmp(formatString, "time") == 0) format = FORMAT_TIME;
	    else if (strcmp(formatString, "threadtime") == 0) format = FORMAT_THREADTIME;
	    else if (strcmp(formatString, "long") == 0) format = FORMAT_LONG;
	    else format = FORMAT_OFF;
	
	    return format;
	}

第一个函数把字符串形式的format转换成整形表示,第二个参数把转换后的format设置到全局变量g_logformat中
	

OK, 到此为止,参数部分就解析完毕.接着执行下面的代码


如果没有指定"-b"参数的话,会默认打开 "main" 和 "system" 两个logger device

    if (!devices) {
        devices = new log_device_t(strdup("/dev/"LOGGER_LOG_MAIN), false, 'm');
        android::g_devCount = 1;
        int accessmode =
                  (mode & O_RDONLY) ? R_OK : 0
                | (mode & O_WRONLY) ? W_OK : 0;
        if (0 == access("/dev/"LOGGER_LOG_SYSTEM, accessmode)) {
            devices->next = new log_device_t(strdup("/dev/"LOGGER_LOG_SYSTEM), false, 's');
            android::g_devCount++;
        }
    }

接下来是设定输出,如果没有指定"-f file"参数,默认输出到标准输出,否则打开file 文件.

	static void setupOutput()
	{
	
	    if (g_outputFileName == NULL) {
	        g_outFD = STDOUT_FILENO;
	    } else {
	        struct stat statbuf;
	        g_outFD = openLogFile (g_outputFileName);
	        fstat(g_outFD, &statbuf);
	        g_outByteCount = statbuf.st_size;
	    }
	}
	
如果有设定log filter的话,会解析字符串并加入到g_logformat的filter链表中	

	for (int i = optind ; i < argc ; i++) {
    	err = android_log_addFilterString(g_logformat, argv[i]);

接下来会打开logger device,然后就是读log了.

    android::readLogLines(devices);

#### 读log

readLogLines()函数通过一个while loop不停的从kernel 层的logger device中读取log

    while (1) {
        do {
            timeval timeout = { 0, 5000 /* 5ms */ }; // If we oversleep it's ok, i.e. ignore EINTR.
            FD_ZERO(&readset);
            for (dev=devices; dev; dev = dev->next) {
                FD_SET(dev->fd, &readset);
            }
            result = select(max + 1, &readset, NULL, NULL, sleep ? NULL : &timeout);
        } while (result == -1 && errno == EINTR);

这里有设一个timeout,最开始这个值为false,标志一直等待有log产生. 如果为true, 表示这段时间内没有新的log产生,则会把以及读出来的log全部flush到输出.

如果select()返回,会检查是否有logger device可读,并尝试从device中读取一条log.

        if (result >= 0) {
            for (dev=devices; dev; dev = dev->next) {
                if (FD_ISSET(dev->fd, &readset)) {
                    queued_entry_t* entry = new queued_entry_t();
                    ret = read(dev->fd, entry->buf, LOGGER_ENTRY_MAX_LEN);

logger device read() 的实现是每次读取一条logger_entry, 并存放到结构体queued_entry_t 的成员变量 buf 中,queued_entry_t 的定义如下:

	struct queued_entry_t {
	    union {
	        unsigned char buf[LOGGER_ENTRY_MAX_LEN + 1] __attribute__((aligned(4)));
	        struct logger_entry entry __attribute__((aligned(4)));
	    };
	    queued_entry_t* next;
	
	    queued_entry_t() {
	        next = NULL;
	    }
	};

可以看到buf和logger_entry被定义成union结构,所以读到buffer的内容同时是一条logger_entry.	该结构体的定义如下
	
	struct logger_entry {
	    uint16_t    len;    /* length of the payload */
	    uint16_t    __pad;  /* no matter what, we get 2 bytes of padding */
	    int32_t     pid;    /* generating process's pid */
	    int32_t     tid;    /* generating process's tid */
	    int32_t     sec;    /* seconds since Epoch */
	    int32_t     nsec;   /* nanoseconds */
	    char        msg[0]; /* the entry's payload */
	};

第一个变量len是字符串msg的长度,所以read()函数返回后会对返回值和len的值做比较,如果不相等,表示读的数据有错误.

	else if (entry->entry.len != ret - sizeof(struct logger_entry)) {
   		fprintf(stderr, "read: unexpected length. Expected %d, got %d\n",
   		entry->entry.len, ret - sizeof(struct logger_entry));
   		exit(EXIT_FAILURE);
   	}

接着会call device变量dev的enqueue()函数把刚读出来的log插入到dev的entry list中,并排序.

    void enqueue(queued_entry_t* entry) {
        if (this->queue == NULL) {
            this->queue = entry;
        } else {
            queued_entry_t** e = &this->queue;
            while (*e && cmp(entry, *e) >= 0) {
                e = &((*e)->next);
            }
            entry->next = *e;
            *e = entry;
        }
    }
	
	static int cmp(queued_entry_t* a, queued_entry_t* b) {
	    int n = a->entry.sec - b->entry.sec;
	    if (n != 0) {
	        return n;
	    }
	    return a->entry.nsec - b->entry.nsec;
	}
