---
layout: default
title: Android Log 系统之 Logcat
---

{{page.title}}
==============

这篇文章介绍android系统中录log的工具 logcat.

Android 系统提供了一整套的API供Java层和Native层的程序写log,以方便调试及在系统出问题的时候有据可查. 
而logcat是把这些抓log的工具,可以通过logcat把log显示到标准输出或文件中,同时还可以对log进行过滤. 设定log level及只读取指定module的log. logcat 的详细用法可以在手机中输入"logcat -h" 命令查看.

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
