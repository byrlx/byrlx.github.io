---
layout: post
title: how i learn python
category: [技术]
tag: [Python]
description: [Some funny thought during python learing]
---

* Part 1: parse files in a folder. 

As a logger admin, i need a program to analyse the log files, find out how many logs are printed during the time, and which programs print the top ten logs.
Log format in the files is *"<date> <time> <pid> <tid> <level> <tag> <log string>"*, what i need is <date>, <time>, <tag>, log numbers of every <tag>, percent of every <tag>. And the most important thing: __sort the output by log numbers of each <tag>__.

I decide to use python do this.

First, i need to open the file and read the content. `open()` returns a file object refers to the file. The return object have a method `readlines()` can read out all the lines to memory (As every log file is no bigger than 20MB, this can be acceptable). The return value is a list of all lines of the file.

Then, traverse the list and calculate how many times a <tag> shows. I need a data structer to save <tag> and calculated number: Dictionary. I define an empty dict first: `dict={}`. Then enter a for loop to traverse the lines list.
For every line, what i need is only tag, `line.split()` can spite the line to several items by space character. Use `dict.has_key(key)` to check whether this key already in dict or not.If so, `dict[key]+=1`; If not, `dict[key]=1`. 
After traverse, the dict has all the <tag> and number out of order, how to sort it by value. Find a good method through stack overflow: 
	sorted_dict = sorted(dict.iteritems(), key=operator.itemgetter(1),reverse=True)
Then print the sorted_dict

Now, i can parse a single file now. But, bad news is: there will be more than 1 log files during a long time. How do i analyse them all ?
Very easy, first, define a list of log files (max log files are fixed in system), add a for loop outside the code metioned before. Meanwhile, get the time of the first line of first log file, last line of last log file to record the begin time and end time
A list record size of each file by call `os.path.getsize(file)`
Can analyse many files

What to do next is analyse log files under different children dirs. Means support a dir parameter pass to program. Can get it through `sys.argv[1]`. Then call `os.chdir(dir)` change the working directory of process
Bazinga !!!

* Part 2: recursivly parse folder

At part 1, a problem needs resolve: how to parse log files under different children dirs ?
As other programming languages, you can write recursive programs. 

A problem is: i use `os.chdir()` to change program to the folder when parse files. When return from a recurse level, the programe path is change, so how to change back after finish one folder?
Use a variable to save the current path before change: `last_dir = os.getcwd()`, after finish parse, call `os.chdir(last_dir)` to change back to orignal path.
OK, now, this program is finished, i can parse every folders under the given path.

* Part 3: There are compressed files under folder.

From part 1 and part 2 i can parse the normal files under every folder, but what if the file in folder is uncompressed files? Uncompress them by hand ? Absolutely NOT....
A new program needed. Written in Python
As last program, this is also recursive. Because you may uncompress many files in many folder as above.

Module `zipfile` and `rarfile` is used to uncompress zip and rar files. Define a function `lx_extract(dir)`, first use `os.listdir(dir)` to list all the files under dir(include subdirs), use a for loop to parse the list result. If the file is also a dir, call `lx_extract()` to enter the function again. Else, use `zipfile.is_zipfile(file)` to check if its a zip file (rar the same), if so, call `zipfile.ZipFile(file)` to get a zip_object, the call the function of this object `zip_obj.extractall(dst_dir)` to extract the zip/rar file.

Aha, the second program done. Can parse every compressed files under the give path, include these in all the subdirs.
Bazinga !!!
	
