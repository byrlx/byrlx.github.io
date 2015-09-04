---
layout: post
title: Android Studio Tips
tag: [Android, Tool]
---

记录 Android Studio 里的技巧和方法.

### 1. Android Studio 1.0升级事项

1. 升级 Gradle plugin 到1.0.0

		dependencies {
			classpath 'com.android.tools.build:gradle:1.0.0'
		}

2. 修改 gradle/wrapper/gradle-wrapper.properties 文件, 将 gradle 的版本
升级到2.2.1.
	
	distributionUrl=http\://services.gradle.org/distributions/gradle-2.2.1-all.zip
	
3. 将 build.gradle 中的 runProgaurd 改为 minifyEnabled

         release {
-            runProguard true
+            minifyEnabled true
			 proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.txt'

### 2. Android Stuido常用方法

1. 在 build.gradle 中的 debug 中加入*debuggable true*来使用 DDMS 来调试应用.
2. 打开"tools->Android->Memory Monitor" 查看内存使用情况.


