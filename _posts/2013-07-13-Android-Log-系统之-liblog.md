---
layout: default
title: Android Log 系统之 liblog
---

{{page.title}}
-----------------------------

在[这篇](http://byrlx.github.io/2013/07/10/Android-Log-%E7%B3%BB%E7%BB%9F%E4%B9%8B-logcat.html)文章介绍了Android系统读log的一个工具logcat. logcat可以很方便的抓取系统中的log,以监控系统的运行状况或进行调试.

那么,这些log是从哪里来的呢???换句话说,如果我们要写一个APK或native的程序,要怎么写log才能被logcat抓出来???

Androi系统提供了一套完整的API供其他程序调用输出log,这套API分为Java 层和 native 层,不过两个API最终都是通过file system将log写入kernel 层的logger device.

#### ALOGX 系列
以native层为例,如果我们要开发'.cpp'或'.c'程序,那么可以call下列API之以写出不同level的log

	#define LOG_TAG "HeloWorld"
	ALOGV("hello world,level verbose");
	ALOGD("hello world,level debug");
	ALOGI("hello world,level info");
	ALOGE("hello world,level error");
	ALOGW("hello world,level warning");

这里通常都需要定义一个LOG_TAG, 作为一个完整log的一部分,可以唯一的定位一个module. ALOGX()系列API的实现通过宏定位到共同的一组函数.

	#ifndef ALOGE
	#define ALOGE(...) ((void)ALOG(LOG_ERROR, LOG_TAG, __VA_ARGS__))
	#endif

	#ifndef ALOG
	#define ALOG(priority, tag, ...) \
	    LOG_PRI(ANDROID_##priority, tag, __VA_ARGS__)
	#endif

	#ifndef LOG_PRI
	#define LOG_PRI(priority, tag, ...) \
	    android_printLog(priority, tag, __VA_ARGS__)
	#endif

	#define android_printLog(prio, tag, fmt...) \
	    __android_log_print(prio, tag, fmt)

	int __android_log_print(int prio, const char *tag, const char *fmt, ...)
	{
	    va_list ap;
	    char buf[LOG_BUF_SIZE];
	
	    va_start(ap, fmt);
	    vsnprintf(buf, LOG_BUF_SIZE, fmt, ap);
	    va_end(ap);
	
	    return __android_log_write(prio, tag, buf);
	}
	
__android_log_print()通过va_list变量把format形式字符串生成最终的字符串,然后调用__android_log_write(),这里的参数tag就是之前定义的 LOG_TAG. 而prio是一个整数值,中[logcat](http://byrlx.github.io/2013/07/10/Android-Log-%E7%B3%BB%E7%BB%9F%E4%B9%8B-logcat.html)讲到过,最后通过logcat抓出来后,会将整形log level转换为字符型.
	
	int __android_log_write(int prio, const char *tag, const char *msg)
	{
	    struct iovec vec[3];
	    log_id_t log_id = LOG_ID_MAIN;
	
	    if (!tag)
	        tag = "";
	
	    /* XXX: This needs to go! */
	    if (!strcmp(tag, "HTC_RIL") ||
	        !strncmp(tag, "RIL", 3) || /* Any log tag with "RIL" as the prefix */
	        !strncmp(tag, "IMS", 3) || /* Any log tag with "IMS" as the prefix */
	        !strcmp(tag, "AT") ||
	        !strcmp(tag, "GSM") ||
	        !strcmp(tag, "STK") ||
	        !strcmp(tag, "CDMA") ||
	        !strcmp(tag, "PHONE") ||
	        !strcmp(tag, "SMS"))
	            log_id = LOG_ID_RADIO;
	
	    vec[0].iov_base   = (unsigned char *) &prio;
	    vec[0].iov_len    = 1;
	    vec[1].iov_base   = (void *) tag;
	    vec[1].iov_len    = strlen(tag) + 1;
	    vec[2].iov_base   = (void *) msg;
	    vec[2].iov_len    = strlen(msg) + 1;
	
	    return write_to_log(log_id, vec, 3);
	}

Android log 系统目前有四种类型的log:main,system,radio,events. 后三种一般都是系统的一些特殊的log,除此之外,自己开发的程序,log都默认写到main中. 所以程序最开始把 log_id 设为 LOG_ID_MAIN. 不过程序接下来会判断tag参数,如果tag符合radio log的规则的话,则将log_id改为 LOG_ID_RADIO. 接着把传入的三个参数放到一个iovec变量中. 并调用write_to_log()
	
	struct iovec {
	    const void*  iov_base;
	    size_t       iov_len;
	};
	
	static int (*write_to_log)(log_id_t, struct iovec *vec, size_t nr) = __write_to_log_init;
	
write_to_log()是一个指针函数,这里的实现用了一点小伎俩. 最开始这个指针就被赋值为__write_to_log_init, 所以,在第一次调用该函数的时候,调用的就是 __write_to_log_init()

	static int __write_to_log_init(log_id_t log_id, struct iovec *vec, size_t nr)
	{
	#ifdef HAVE_PTHREADS
	    pthread_mutex_lock(&log_init_lock);
	#endif
	
	    if (write_to_log == __write_to_log_init) {
	        log_fds[LOG_ID_MAIN] = log_open("/dev/"LOGGER_LOG_MAIN, O_WRONLY);
	        log_fds[LOG_ID_RADIO] = log_open("/dev/"LOGGER_LOG_RADIO, O_WRONLY);
	        log_fds[LOG_ID_EVENTS] = log_open("/dev/"LOGGER_LOG_EVENTS, O_WRONLY);
	        log_fds[LOG_ID_SYSTEM] = log_open("/dev/"LOGGER_LOG_SYSTEM, O_WRONLY);
	
	        write_to_log = __write_to_log_kernel;
	
	        if (log_fds[LOG_ID_MAIN] < 0 || log_fds[LOG_ID_RADIO] < 0 ||
	                log_fds[LOG_ID_EVENTS] < 0) {
	            log_close(log_fds[LOG_ID_MAIN]);
	            log_close(log_fds[LOG_ID_RADIO]);
	            log_close(log_fds[LOG_ID_EVENTS]);
	            log_fds[LOG_ID_MAIN] = -1;
	            log_fds[LOG_ID_RADIO] = -1;
	            log_fds[LOG_ID_EVENTS] = -1;
	            write_to_log = __write_to_log_null;
	        }
	
	        if (log_fds[LOG_ID_SYSTEM] < 0) {
	            log_fds[LOG_ID_SYSTEM] = log_fds[LOG_ID_MAIN];
	        }
	    }
	
	#ifdef HAVE_PTHREADS
	    pthread_mutex_unlock(&log_init_lock);
	#endif
	
	    return write_to_log(log_id, vec, nr);
	}
	
之所以要这样做,是因为在系统开启后第一次写通过ALOGX函数写log的时候,kernel 层的logger device还未被打开,所以要将这些device都打开,然后,将write_to_log改成__write_to_log_kernel. 在函数的最后,接着再调用一次write_to_log(),这次调用的就是__write_log_log_kernel 了.

	static int __write_to_log_kernel(log_id_t log_id, struct iovec *vec, size_t nr)
	{
	    ssize_t ret;
	    int log_fd;
	
	    if (/*(int)log_id >= 0 &&*/ (int)log_id < (int)LOG_ID_MAX) {
	        log_fd = log_fds[(int)log_id];
	    } else {
	        return EBADF;
	    }
	
	    do {
	        ret = log_writev(log_fd, vec, nr);
	    } while (ret < 0 && errno == EINTR);
	
	    return ret;
	}

函数将log_id转为log_fd后,就直接调用 log_writev()函数

	#define log_writev(filedes, vector, count) writev(filedes, vector, count)

log_writev()就被映射到具体的driver层的writev()函数.这样,一条log就被写入到了kernel层的device中.

#### SLOGX

SLOGX()API族用于生成system log,log被写到system这个logger device中,SLOGX的实现跟main log基本相同,只是默认的log id是system而不是main
	
	#define SLOGV(...) ((void)__android_log_buf_print(LOG_ID_SYSTEM, ANDROID_LOG_VERBOSE, LOG_TAG, __VA_ARGS__))
	
	int __android_log_buf_print(int bufID, int prio, const char *tag, const char *fmt, ...)
	{
	    va_list ap;
	    char buf[LOG_BUF_SIZE];
	
	    va_start(ap, fmt);
	    vsnprintf(buf, LOG_BUF_SIZE, fmt, ap);
	    va_end(ap);
	
	    return __android_log_buf_write(bufID, prio, tag, buf);
	}
	
	int __android_log_buf_write(int bufID, int prio, const char *tag, const char *msg)
	{
	    struct iovec vec[3];
	
	    if (!tag)
	        tag = "";
	
	    /* XXX: This needs to go! */
	    if (!strcmp(tag, "HTC_RIL") ||
	        !strncmp(tag, "RIL", 3) || /* Any log tag with "RIL" as the prefix */
	        !strncmp(tag, "IMS", 3) || /* Any log tag with "IMS" as the prefix */
	        !strcmp(tag, "AT") ||
	        !strcmp(tag, "GSM") ||
	        !strcmp(tag, "STK") ||
	        !strcmp(tag, "CDMA") ||
	        !strcmp(tag, "PHONE") ||
	        !strcmp(tag, "SMS"))
	            bufID = LOG_ID_RADIO;
	
	    vec[0].iov_base   = (unsigned char *) &prio;
	    vec[0].iov_len    = 1;
	    vec[1].iov_base   = (void *) tag;
	    vec[1].iov_len    = strlen(tag) + 1;
	    vec[2].iov_base   = (void *) msg;
	    vec[2].iov_len    = strlen(msg) + 1;
	
	    return write_to_log(bufID, vec, 3);
	}
