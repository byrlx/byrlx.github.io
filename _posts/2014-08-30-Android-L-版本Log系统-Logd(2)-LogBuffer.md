---
layout: default
title: Android L 版本Log系统之 Logd(2):LogBuffer
---

{{page.title}}
-------------------------------

#### 1. 什么是LogBuffer？

LogBuffer是Logd系统的核心。可以把LogBuffer看成一个大容器，
几乎所有Logd操作的内容，包括log存放，客户端管理，统计信息，
都是对LogBuffer内容的操作。

在logd系统运行过程中，有且仅有一个LogBuffer对象。


#### 2. 代码实现

下面一行行的看LogBuffer的代码。
	
	class LogBuffer {
	    LogBufferElementCollection mLogElements;
	    pthread_mutex_t mLogElementsLock;
	
	    LogStatistics stats;
	
	    bool dgram_qlen_statistics;
	
	    PruneList mPrune;
	
	    unsigned long mMaxSize[LOG_ID_MAX];
	
	public:
	    LastLogTimes &mTimes;
	
	    LogBuffer(LastLogTimes *times);
	
	    void log(log_id_t log_id, log_time realtime,
	             uid_t uid, pid_t pid, pid_t tid,
	             const char *msg, unsigned short len);
	    log_time flushTo(SocketClient *writer, const log_time start,
	                     bool privileged,
	                     bool (*filter)(const LogBufferElement *element, void *arg) = NULL,
	                     void *arg = NULL);
	
	    void clear(log_id_t id, uid_t uid = AID_ROOT);
	    unsigned long getSize(log_id_t id);
	    int setSize(log_id_t id, unsigned long size);
	    unsigned long getSizeUsed(log_id_t id);
	    // *strp uses malloc, use free to release.
	    void formatStatistics(char **strp, uid_t uid, unsigned int logMask);
	
	    void enableDgramQlenStatistics() {
	        stats.enableDgramQlenStatistics();
	        dgram_qlen_statistics = true;
	    }
	
	    int initPrune(char *cp) { return mPrune.init(cp); }
	    // *strp uses malloc, use free to release.
	    void formatPrune(char **strp) { mPrune.format(strp); }
	
	    // helper
	    char *pidToName(pid_t pid) { return stats.pidToName(pid); }
	    uid_t pidToUid(pid_t pid) { return stats.pidToUid(pid); }
	
	private:
	    void maybePrune(log_id_t id);
	    void prune(log_id_t id, unsigned long pruneRows, uid_t uid = AID_ROOT);
	
	};
