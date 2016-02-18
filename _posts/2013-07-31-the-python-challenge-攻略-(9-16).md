---
layout: post
title: The python challenge 攻略(9-16)
description: [Answers about python challenge, part 2]
category: Life
tag: [Tech]
---

[上篇文章](http://byrlx.github.io/2013/06/16/the-python-challenge-%E6%94%BB%E7%95%A5-%281-8%29.html)介绍了[The python challenge](http://www.pythonchallenge.com/) 这个网站前面几关的攻略, 这篇文章继续讲解后面各关的攻略.

#### Level Nine

从上一关算出这关的网址之后,打开,是一张图片,图片内容是一个可爱的小蜜蜂中菊花上采蜜.图片下面有一行字.  "where is the missing link ?"

有点摸不着头绪,老规矩,源码搞起.源码中果然有个 link,点击,出现一个对话框,要求输入用户名和密码, 提示文字最后有这样一段话: the site says:"inflate"

突然想起源码最后的注释中有看上去有那么一点像是用户名和密码的文字
	
	<!--
	un: 'BZh91AY&SYA\xaf\x82\r\x00\x00\x01\x01\x80\x02\xc0\x02\x00 \x00!\x9ah3M\x07<]\xc9\x14\xe1BA\x06\xbe\x084'
	pw: 'BZh91AY&SY\x94$|\x0e\x00\x00\x00\x81\x00\x03$ \x00!\x9ah3M\x13<]\xc9\x14\xe1BBP\x91\xf08'
	-->

我敢打赌,如果原样输入上面的内容,肯定不会进入下一关(鬼都知道). 后来就一直想 inflate 到底是个什么东西. 谷歌搜了一下,发现是压缩和解压缩相关的知识,这方面丝毫不懂啊.用 python 的 zlib 模块试着解压了一下.不行.

后来又继续看这两段压缩文字,发现开头都是相同的,于是又谷歌之,发现是 bz2 压缩格式的 header 形式,于是试着找 python 的 bz2 模块.
	
	#!/usr/bin/python
	
	import bz2
	
	un = 'BZh91AY&SYA\xaf\x82\r\x00\x00\x01\x01\x80\x02\xc0\x02\x00 \x00!\x9ah3M\x07<]\xc9\x14\xe1BA\x06\xbe\x084'
	pa = 'BZh91AY&SY\x94$|\x0e\x00\x00\x00\x81\x00\x03$ \x00!\x9ah3M\x13<]\xc9\x14\xe1BBP\x91\xf08'
	
	print bz2.decompress(un)
	print bz2.decompress(pa)

呃,没想到误打误撞,竟找到了答案.
