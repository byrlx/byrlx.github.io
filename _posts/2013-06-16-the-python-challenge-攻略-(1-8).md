---
layout: default
title: The python challenge 攻略(1-8)
---

{{page.title}}
-----------------------------

[The python challenge](http://www.pythonchallenge.com/) 是一个网站,里面的每一个网页都是一个迷题,把迷题解开后可以找到下一关的网址.当然,这些迷题的代码要用python写哦.
进入[主页](http://www.pythonchallenge.com/),点击*Click here to get challenged*,开始挑战.

#### Level One

页面只有一张图片,图片内容是一个电脑,上面显示了一个数字:2\*\*38. OK,求出结果,并将结果替换掉作为url地址.
下一关的地址就是http://www.pythonchallenge.com/pc/def/*274877906944*.html

	#!/usr/bin/python
	
	print 2**38

#### Level Two

第二关还是一张图片,只不过图片下边多了两段文字:

>"everybody thinks twice before solving this."

>"g fmnc wms bgblr rpylqjyrc gr zw fylb. rfyrq ufyr amknsrcpq ypc dmp. bmgle gr gl zw fylb gq glcddgagclr ylb rfyr'q ufw rfgq rcvr gq qm jmle. sqgle qrpgle.kyicrpylq() gq pcamkkclbcb. lmu ynnjw ml rfc spj."

不难看出,第一行大家应该都能看懂,不过第二行嘛......
所以第二行肯定就是密文,下一关的线索就在里面,不过要怎么破解密文.回过头来看图片,图片的内容是三个字母*"K O E"*分别对应到另外的三个字母*"M Q G"*,分析一下可以发现,后三个字母和前三个字母的间隔相同,即`M-K=Q-O=G-E=2`,所以破解密文的方法就是把所有字母变成对应后的字母,记住:只改变字母.
不过,就像第一行文字提醒的那样,'y'和'z'的改变可不是单纯的加2,而是要变成'a'和'b'哦.
	
	#!/usr/bin/python
	
	import string
	fd = open("level2.txt",'r')
	lx_str = fd.read()
	table = string.maketrans("abcdefghijklmnopqrstuvwxyz","cdefghijklmnopqrstuvwxyzab")

	print lx_str.translate(table)
翻译之后的结果是
>i hope you didnt translate it by hand. thats what computers are for. doing it in by hand is inefficient and that's why this text is so long. using string.maketrans() is recommended. now apply on the url.

所以还要把url按照该方法转换一下,'map'=>'ocr',这就是下一关的地址.
	
#### Level Three

第三关仍然是一张图片和一行文字,看文字就知道要找的东西不在图片中,而是在网页源代码中(什么,文字你没看懂???请先去老罗和他的朋友们英语培训报个班吧).

这一关的工作都在源代码的注释里: 
>"从一大堆火星文中找出出现次数比较少的单词."

面对如此多的文字,大体上看了一眼之后,笔者做了一个比较偷懒的尝试:找出所有的字母和数字.

	#!/usr/bin/python
	
	lx_file = open("level3.txt","r")
	lx_str = lx_file.read()
	
	lxlist = list(lx_str)
	lxresult = []
	for lxchr in lxlist:
		if lxchr.isdigit():
			lxresult.append(lxchr)
			continue
		if lxchr.isalpha():
			lxresult.append(lxchr)
			continue
	
	print "".join(lxresult)

懒人有懒福,第一次尝试竟然成功了,结果竟然是正确的,看来前面几关果然还是比较简单的.

不过,笔者刚接触python不久,上面的代码写的很低效,而且有蒙的嫌疑,来看下官方给出的代码:
	
	s = ''.join([line.rstrip() for line in open('ocr.txt')])    
	OCCURRENCES = {}
	for c in s: OCCURRENCES[c] = OCCURRENCES.get(c, 0) + 1
	avgOC = len(s) // len(OCCURRENCES)
		print ''.join([c for c in s if OCCURRENCES[c] < avgOC]) 
	
第一行把N行文本结合成了一个大长句,然后通过字典计算每个字符出现的次数,最后打印出现次数小于平均数的字符.

#### Level Four

第四关依旧是一张图片,但是迷题在图片的下面:
>"One small letter, surrounded by EXACTLY three big bodyguards on each of its sides."

翻译成中文就是:找出所有左右有3个大写字母的小写字母.

这一关很明显是在考正则表达式,笔者上网查了一些正则表达式的资料后写出了下面的代码:

	#!/usr/bin/python
	
	import re
	
	lxline = "".join([line.rstrip() for line in open("level4.txt")])
	
	pa = re.compile(r'[^A-Z][A-Z]{3}([a-z])[A-Z]{3}[^A-Z]')
	m  = pa.match(lxline)
	print m.groups()

但是,运行后程序程序输出为空.不知道为什么`match()`函数会这样?改用`findall()`就没有问题了.

	#!/usr/bin/python
	
	import re
	
	lxline = "".join([line.rstrip() for line in open("level4.txt")])
	
	pa = re.compile(r'[^A-Z][A-Z]{3}([a-z])[A-Z]{3}[^A-Z]')
	print ''.join(pa.findall(lxline))
