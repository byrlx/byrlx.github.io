---
layout: post
title: Android Logcat
tags: [Android, Log]
---

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

插入的算法是从链表头开始已有entry与新entry的时间戳,如果新entry的产生时间比较晚,就继续与下一个entry比较. 其实理论上讲,晚到来的log总是产生时间晚的log,所以这种比较的比较次数一般要大于从尾部开始比较. 另外值得一提的是比较算法采用了指针的指针,比较简洁,避免插入时链表头的判断. Linus大婶曾经在一次访谈中说道"这才是指针的真正用法".......

接下来会打印log,需要说明的是没读出一次log就会判断是否需要打印log. 如果是select超时返回,会打印所有"需要"打印的log(这里加所有是因为如果使用"t"参数的话,只会打印最新的几条log),否则,会打印除最后一条log以外的所有log,剩一条log是为了下次时间戳的比较.

  	while (g_tail_lines == 0 || queued_lines > g_tail_lines) {
    	chooseFirst(devices, &dev);
       	if (dev == NULL || dev->queue->next == NULL) {
        	break;
        }
        if (g_tail_lines == 0) {
        	printNextEntry(dev);
        } else {
            skipNextEntry(dev);
        }
        --queued_lines;

chooseFirst()函数会把device链表中包含最新log的device选出来,这样对于多种类型的log输出到同一个文件的case,可以保证log按时间排序.
	
	static void chooseFirst(log_device_t* dev, log_device_t** firstdev) {
	    for (*firstdev = NULL; dev != NULL; dev = dev->next) {
	        if (dev->queue != NULL && (*firstdev == NULL || cmp(dev->queue, (*firstdev)->queue) < 0)) {
	            *firstdev = dev;
	        }
	    }
	}
	
接着就是call printNextEntry()进行log输出.

	static void printNextEntry(log_device_t* dev) {
	    maybePrintStart(dev);
	    if (g_printBinary) {
	        printBinary(&dev->queue->entry);
	    } else {
	        processBuffer(dev, &dev->queue->entry);
	    }
	    skipNextEntry(dev);
	}

如果中指定了"B"参数,log将不会被解析,直接以二进制的方式输出,否则,调用 processBuffer()对log entry进行解析.

    if (dev->binary) {
        err = android_log_processBinaryLogBuffer(buf, &entry, g_eventTagMap,
                binaryMsgBuf, sizeof(binaryMsgBuf));
        //printf(">>> pri=%d len=%d msg='%s'\n",
        //    entry.priority, entry.messageLen, entry.message);
    } else {
        err = android_log_processLogBuffer(buf, &entry);
    }

android log system目前有四种类型的log: main, system, radio, event. 其中前三种可以分为同一类型,log可以通过android_log_processLogBuffer()直接解析成人类可以读懂的文字. event log则稍有不同,解析后的log也要通过相应的文件才能读懂. 这里主要看一下常规log的解析.

android_log_processLogBuffer()的参数有两个,第一个是logger_entry变量,第二个是AndroidLogEntry变量,其实这两个结构体的内容大致相同,只不过后一个包含的信息更多一些.

	struct logger_entry {
	    uint16_t    len;    /* length of the payload */
	    uint16_t    __pad;  /* no matter what, we get 2 bytes of padding */
	    int32_t     pid;    /* generating process's pid */
	    int32_t     tid;    /* generating process's tid */
	    int32_t     sec;    /* seconds since Epoch */
	    int32_t     nsec;   /* nanoseconds */
	    char        msg[0]; /* the entry's payload */
	};
		
	typedef struct AndroidLogEntry_t {
	    time_t tv_sec;
	    long tv_nsec;
	    android_LogPriority priority;
	    int32_t pid;
	    int32_t tid;
	    const char * tag;
	    size_t messageLen;
	    const char * message;
	} AndroidLogEntry;
	
	int android_log_processLogBuffer(struct logger_entry *buf,
	                                 AndroidLogEntry *entry)
	{
	    entry->tv_sec = buf->sec;
	    entry->tv_nsec = buf->nsec;
	    entry->pid = buf->pid;
	    entry->tid = buf->tid;
	
	    int msgStart = -1;
	    int msgEnd = -1;
	
	    int i;
	    for (i = 1; i < buf->len; i++) {
	        if (buf->msg[i] == '\0') {
	            if (msgStart == -1) {
	                msgStart = i + 1;
	            } else {
	                msgEnd = i;
	                break;
	            }
	        }
	    }
	
	    entry->priority = buf->msg[0];
	    entry->tag = buf->msg + 1;
	    entry->message = buf->msg + msgStart;
	    entry->messageLen = msgEnd - msgStart;
	
	    return 0;
	}

可以看到转换函数主要是把logger_entry的msg给分割成三个部分:priority, tag, message.

接着会调用android_log_shouldPrintLine()检查该该tag及该level的log是否应该被打印,如果是,则调用android_log_printLogLine()打印.

	/* android_log_printLogLine() */

    outBuffer = android_log_formatLogLine(p_format, defaultBuffer,
            sizeof(defaultBuffer), entry, &totalLen);

    do {
        ret = write(fd, outBuffer, totalLen);
    } while (ret < 0 && errno == EINTR);

	......

    if (outBuffer != defaultBuffer) {
        free(outBuffer);
    }

前面讲过可以通过参数"-v"设置打印的log格式,所以android_log_formatLogLine()的作用就是将entry 转换为最终的打印格式.


	/* android_log_formatLogLine() */

    priChar = filterPriToChar(entry->priority);
    ptm = localtime(&(entry->tv_sec));
    strftime(timeBuf, sizeof(timeBuf), "%m-%d %H:%M:%S", ptm);

    size_t prefixLen, suffixLen;

    switch (p_format->format) {
        case FORMAT_TAG:
            prefixLen = snprintf(prefixBuf, sizeof(prefixBuf),
                "%c/%-8s: ", priChar, entry->tag);
            strcpy(suffixBuf, "\n"); suffixLen = 1;
            break;
        case FORMAT_PROCESS:
            prefixLen = snprintf(prefixBuf, sizeof(prefixBuf),
                "%c(%5d) ", priChar, entry->pid);
            suffixLen = snprintf(suffixBuf, sizeof(suffixBuf),
                "  (%s)\n", entry->tag);
            break;
        case FORMAT_THREAD:
            prefixLen = snprintf(prefixBuf, sizeof(prefixBuf),
                "%c(%5d:%5d) ", priChar, entry->pid, entry->tid);
            strcpy(suffixBuf, "\n");
            suffixLen = 1;
            break;
        case FORMAT_RAW:
            prefixBuf[0] = 0;
            prefixLen = 0;
            strcpy(suffixBuf, "\n");
            suffixLen = 1;
            break;
        case FORMAT_TIME:
            prefixLen = snprintf(prefixBuf, sizeof(prefixBuf),
                "%s.%03ld %c/%-8s(%5d): ", timeBuf, entry->tv_nsec / 1000000,
                priChar, entry->tag, entry->pid);
            strcpy(suffixBuf, "\n");
            suffixLen = 1;
            break;
        case FORMAT_THREADTIME:
            prefixLen = snprintf(prefixBuf, sizeof(prefixBuf),
                "%s.%03ld %5d %5d %c %-8s: ", timeBuf, entry->tv_nsec / 1000000,
                entry->pid, entry->tid, priChar, entry->tag);
            strcpy(suffixBuf, "\n");
            suffixLen = 1;
            break;
        case FORMAT_LONG:
            prefixLen = snprintf(prefixBuf, sizeof(prefixBuf),
                "[ %s.%03ld %5d:%5d %c/%-8s ]\n",
                timeBuf, entry->tv_nsec / 1000000, entry->pid,
                entry->tid, priChar, entry->tag);
            strcpy(suffixBuf, "\n\n");
            suffixLen = 2;
            prefixSuffixIsHeaderFooter = 1;
            break;
        case FORMAT_BRIEF:
        default:
            prefixLen = snprintf(prefixBuf, sizeof(prefixBuf),
                "%c/%-8s(%5d): ", priChar, entry->tag, entry->pid);
            strcpy(suffixBuf, "\n");
            suffixLen = 1;
            break;
    }

    size_t numLines;
    size_t i;
    char *p;
    size_t bufferSize;
    const char *pm;


    ret[0] = '\0';       /* to start strcat off */

    p = ret;
    pm = entry->message;


首先会将数字格式的priority转为字符格式,接着生成格式化时间字符串.然后进入switch判断当前的format形式,并生成对应的prefix. 因为snprintf/vsnprintf有个特点:虽然它们最多只会向buffer写入指定长度的字符串(也就是说,如果buffer不足,字符串会被截断),但是,它们的返回值确是理想情况下(buffer足够大)可以写入的字符串长度.所以程序接下来会判断返回值跟buffer size是否相等.

	/* android_log_formatLogLine() */
    if(prefixLen >= sizeof(prefixBuf))
        prefixLen = sizeof(prefixBuf) - 1;
    if(suffixLen >= sizeof(suffixBuf))
        suffixLen = sizeof(suffixBuf) - 1;

接着会遍历msg中的"\n"判断该条log需要分几行打出,每行打出的log都会有prefix字符串

	/* android_log_formatLogLine() */
    if (prefixSuffixIsHeaderFooter) {
        numLines = 1;
    } else {
        pm = entry->message;
        numLines = 0;

        while (pm < (entry->message + entry->messageLen)) {
            if (*pm++ == '\n') numLines++;
        }
        if (pm > entry->message && *(pm-1) != '\n') numLines++;
    }

在函数参数中已经传入了存log的buffer,但是,如果需要打印的log 长度超过了buffer size,则系统会重新malloc一个新的buffer,记住:这个buffer需要在函数外free掉!!!!(logcat的做法是判断函数返回值是否等于传入的buffer,如果不是,则表示有新buffer malloc,就会free掉)

	/* android_log_formatLogLine() */
    bufferSize = (numLines * (prefixLen + suffixLen)) + entry->messageLen + 1;

    if (defaultBufferSize >= bufferSize) {
        ret = defaultBuffer;
    } else {
        ret = (char *)malloc(bufferSize);

        if (ret == NULL) {
            return ret;
        }
    }

	/* android_log_printLogLine() */
    if (outBuffer != defaultBuffer) {
        free(outBuffer);
    }

最后是生成最终的log字符串.对于"long"格式的log format来讲,prefix只需打印一次,所以不需要遍历msg中的"\n".否则,对于每行log都要加上prefix.

    if (prefixSuffixIsHeaderFooter) {
        strcat(p, prefixBuf);
        p += prefixLen;
        strncat(p, entry->message, entry->messageLen);
        p += entry->messageLen;
        strcat(p, suffixBuf);
        p += suffixLen;
    } else {
        while(pm < (entry->message + entry->messageLen)) {
            const char *lineStart;
            size_t lineLen;
            lineStart = pm;

            // Find the next end-of-line in message
            while (pm < (entry->message + entry->messageLen)
                    && *pm != '\n') pm++;
            lineLen = pm - lineStart;

            strcat(p, prefixBuf);
            p += prefixLen;
            strncat(p, lineStart, lineLen);
            p += lineLen;
            strcat(p, suffixBuf);
            p += suffixLen;

            if (*pm == '\n') pm++;
        }
    }

    if (p_outLength != NULL) {
        *p_outLength = p - ret;
    }

    return ret;

函数返回后,就把最终字符串写到输出. 

OK,logcat的用法及实现流程到这里就基本结束了.