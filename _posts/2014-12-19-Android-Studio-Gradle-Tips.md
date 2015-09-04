---
layout: post
title: Android Studio Gradle Tips
tags: [Android, Gradle]
categories: [Tools]
---

Record some gradle command tips for android studio project.
Android Studio will build a *gradlw* file under the root
directory, which is the command to do things.

### Android gradle enviroment

1.  There should be a *build.gradle* under the root directory.
	
	buildscript {
	    repositories {
	        mavenCentral()
	    }
	
	    dependencies {
	        classpath 'com.android.tools.build:gradle:0.11.1'
	    }
	}
	
	apply plugin: 'android'

	//define the global build version
	android {
	    compileSdkVersion 19
	    buildToolsVersion "19.0.0"
	}

2. (If not set ANDROID_HOME)There should be a file *local.properties* defines the sdk path

	sdk.dir=/Users/LX/LX/sdk

3. settings.gradle 文件指明那些 module 需要被 build.

### build.gradle for each module

1. 可以在 android->buildType->debug 中设置 applicationIdSuffix "xxxx" 来指定 debug 版本的 applicationId,
这样可以同时在手机里安装 debug 和 release 版本.

2. 可以通过分别设置 src/<buildtypename>/ 来针对不同的 build type, 实现编译不同的版本使用不同的代码.

### Useful commands

1. gradlew tasks: show the toplevel tasks of the project.
"--all" option will show all the tasks

		Android tasks
		-------------
		androidDependencies - Displays the Android dependencies of the project
		signingReport - Displays the signing info for each variant
	
		Build tasks
		-----------
		assemble - Assembles all variants of all applications and secondary packages.
		assembleDebug - Assembles all Debug builds
		assembleDebugTest - Assembles the Test build for the Debug build
		assembleRelease - Assembles all Release builds
		build - Assembles and tests this project.
		buildDependents - Assembles and tests this project and all projects that depend on it.
		buildNeeded - Assembles and tests this project and all projects it depends on.
		clean - Deletes the build directory.
		extractDebugAnnotations - Extracts Android annotations for the debug variant into the archive file
		extractReleaseAnnotations - Extracts Android annotations for the release variant into the archive file
	
2. gradlew projects: Display all the sub-projects.
usually traverse all the "build.gradle" files under the sub projects.

3. gradlew module:assembleDebug : build a debug version apk

4. gradlew module:assembleRelease : build a release version apk
