---
layout: default
title: What do I learn from the project
---

{{page.title}}
------------------------

今年做过的一个项目的总结，记下有用的经验。

#### 1. 做好前期规划

一定对你即将做的东西有一个整体的轮廓，首先要明确这个东西是什么，具有什么样的功能。然后，划分模块，每个模块要做什么事情，最大化实现模块之间的低耦合度，模块之间尽量用最少的API。定义每个模块的API，最好能细化到应该用几个线程或函数实现该模块。

我觉得这个过程是非常重要的，如果是一个team共同做这个东西，一定要经常性的开会讨论，反复修改。如果是一个人做，也要把架构图完整的描述出来，并不断的review。虽然很多人（包括我）都喜欢上来就直接写代码，但是这次项目经验让我了解到，前期架构描述的越完整，后期的改动就会越小。

#### 2. 用Git维护代码库

当然也可以用别的版本库工具，但是人人都爱git。

我是个略有“洁癖”的人，有时候看到一些无关痛痒的地方，例如代码命名、格式等不顺眼，都喜欢改一下。但我还是认为不要把每次这种细小的改动都当成一次修改提交到git中，这会使log记录变得冗长且无用。尽量使每一次提交都是有意义的提交，像是修改bug、修改功能或是增加新功能。

写好gitignore文件，只追踪git库的源代码文件。忽略掉tags,cscope.out这些有用经常出现的文件。设定你喜欢的颜色输出，尤其是git diff。有git format-patch 最好加上'-s'，这样人人都知道是你提供的patch了。

用好git tag。

#### 3. 写好Test Case

前辈经常教育我们：你的代码，只有你自己最懂。写好test case的一个好处就是：不用每次写完一段代码都要人工测试。

另一个好处就是：可以顺便学习一门新语言，例如python。

基本功能的test case是必须的，你的模块具备什么样的功能，你就要写case测试他有没有这些功能。

