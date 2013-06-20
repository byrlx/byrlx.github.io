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

但是,运行后程序程序输出为空.不知道为什么`match()`函数会这样?改用`findall()`就没有问题了.后来查资料发现原因是:

>match() 函数只会检查是否在字符串*开始处*匹配 !!!

	#!/usr/bin/python
	
	import re
	
	lxline = "".join([line.rstrip() for line in open("level4.txt")])
	pa = re.compile(r'[^A-Z][A-Z]{3}([a-z])[A-Z]{3}[^A-Z]')
	print ''.join(pa.findall(lxline))

#### Level Five

输入第五关的地址,结果显示了另一个网址,输入这个网址后,只有一张图片,连解释的字符串都没有了,按照前两关的规律,还是直接看源码吧.源码中有这样一段注释:

>"\<!-- urllib may help. DON'T TRY ALL NOTHINGS, since it will never 
end. 400 times is more than enough. -->"

刚开始没看懂,后来继续看源码发现图片是一张链接,点击图片,转到另一个网址`http://www.pythonchallenge.com/pc/def/linkedlist.php?nothing=12345`, 这个网页上也只有一行字:

>and the next nothing is 44827

把这串数字替换掉网址上的*nothing*后面的数字,又转到另一个网址,又是一行字,又是替掉现在网址的数字........现在你再回头看注释,似乎明白了什么.

迷题就是:找到最后的链接

这个题目是考urllib库的使用,每个页面都会给出下一个网页的链接,当然你可以一个一个点来找到答案......
程序代码如下:

	#!/usr/bin/python
	
	import urllib
	import re
	
	baseurl = "http://www.pythonchallenge.com/pc/def/linkedlist.php?nothing="
	starturl = baseurl+"12345"
	
	print starturl
	pattern = re.compile(r'[0-9]{1,}')
	
	while True:
		file = urllib.urlopen(starturl)
		lxstr = ''.join(file.readlines())
		print lxstr
		pat = pattern.findall(lxstr)
		nextnum = ''.join(pat)
		starturl = baseurl + nextnum

不要以为写完程序,就可以喝茶等结果了,因为这可能是个没有尽头的循环,想想前面的那句话*400times is more than enough*	, 所以这里面肯定有猫腻......

运行一段时间后,会出现下面的话,

>Yes. Divide by two and keep going.

把前面的数字除以二,替换掉程序中的*12345*, 继续运行

过了一段时间,页面又出现下面一句话:
>There maybe misleading numbers in the text. One example is 82683. Look only for the next nothing and the next nothing is 63579

过了一段时间,又出现了一句话:
>peak.html

Bazinga!!! You got the answer at last

#### Level Six

欢迎来到第六关
