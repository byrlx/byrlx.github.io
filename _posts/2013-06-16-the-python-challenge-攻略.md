---
layout: default
title: The python challenge 攻略
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
	
