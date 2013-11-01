---
layout: default
title: Welcome 'ack' be the new member of my toolbox 
---

{{page.title}}
-------------------

有一次跟台湾同事聊天，聊到在代码库里找key word，我就抱怨说find+grep 的时间太长，
几十G的代码库，往往要找上一个多小时。同事就给我推荐了‘ack’这个工具，说这个tool搜代码比较快一些。

"于是，我抱着试试看的态度,试用了一段时间"...结果就是，我现在几乎不怎么用grep了，而且我决定把它加入到
我的toolbox当中，就像git一样。

ack(ubuntu上叫ack-grep) 是一款搜索工具，就像作者说的那样，*"a tool like grep, optimized for programmers"*，它尤其适用于
代码库大且层次比较多的地方。作者用perl5实现了ack的全部代码。

之所以称ack为“程序员的grep”，是因为ack在代码搜索方面做了很大的优化，默认情况下，ack只会在它“认识”的文件类型
中做搜索。而ack认识的大部分文件类型即位代码文件。同时，也可以使用“--type=X”或“--X”指定在特定的代码文件中搜索。
这些都可以在ack的文档中找到。

例如：ack --type=php keyword 只会在php类型的文件中做搜索（.php .phpt .php3 .php4 .php5 .phtml）。
也可以这样写：ack --php keyword。（记住c文件的话要写成cc）。当然也可以通过在类型面前加“no”指定不搜索
该类型的文件。

通过设定“-g”选项，可以只搜索文件，就是一个简单的find命令了。

另外一个比较迷人的地方是会把搜索结果的keyword高亮，也可以通过这三个选项“--color-filename=COLOR, --color-match=COLOR, --color-lineno=COLOR” 定制化自己的颜色主题。

OK,常用的功能基本就是这些了，更多功能可以去[官方网站](http://beyondgrep.com/)查看了。
