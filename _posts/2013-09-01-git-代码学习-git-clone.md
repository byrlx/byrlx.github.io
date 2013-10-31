---
layout: default
title: git 代码学习 git clone
---

{{page.title}}
-------------------

代码版本：1.8.3

最近一直使用git进行代码开发（公司用的管理工具为perforce，不管用git p4可以实现用git对perforce的对接），深感git的实用和伟大。故抽时间学习一下git的代码，提高功力。

从git.c的main()开始代码之旅。

输入“git clone srcpath despath”后，会执行handle_internal_command()函数。

	if (!prefixcmp(cmd, "git-")) {
		cmd += 4;
		argv[0] = cmd;
		handle_internal_command(argc, argv);
		die("cannot handle %s internally", cmd);
	}

handle_interval_command() 中有定义一个巨大的数组cmd_struct_commands，该数组包含了所有的命令和对应的函数。所以该函数的主要作用就是根据传入的参数遍历数组，找到对应的命令和函数，并执行函数。

	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		struct cmd_struct *p = commands+i;
		if (strcmp(p->cmd, cmd))
			continue;
		exit(run_builtin(p, argc, argv));
	}

在函数run_builtin()用有一句“p->fn(argc,argv,prefix)”，这句代码的意思就是执行该命令对应的函数，这里是cmd_clone(),执行到这里后就会跳转到clone这个命令的代码流程，源文件为“builtin/clone.c”. 
cmd_clone()函数的一开始就定义了一大坨变量，看得有点晕，不过先不管，先从后面的code一句一句分析。

	junk_pid = getpid();
	packet_trace_identity("clone");
	argc = parse_options(argc, argv, prefix, builtin_clone_options,
			     builtin_clone_usage, 0);

第一句无需多言，就是获得pid。第二句通过strdup()函数把packet_trace_prefix 变量赋值为“clone”. 接着执行parse_options()函数
	
	int parse_options(int argc, const char **argv, const char *prefix,
			  const struct option *options, const char * const usagestr[],
			  int flags)
	{
		struct parse_opt_ctx_t ctx;
	
		parse_options_start(&ctx, argc, argv, prefix, options, flags);
		switch (parse_options_step(&ctx, options, usagestr)) {
		case PARSE_OPT_HELP:
			exit(129);
		case PARSE_OPT_NON_OPTION:
		case PARSE_OPT_DONE:
			break;
		default: /* PARSE_OPT_UNKNOWN */
			if (ctx.argv[0][1] == '-') {
				error("unknown option `%s'", ctx.argv[0] + 2);
			} else if (isascii(*ctx.opt)) {
				error("unknown switch `%c'", *ctx.opt);
			} else {
				error("unknown non-ascii option in string: `%s'",
				      ctx.argv[0]);
			}
			usage_with_options(usagestr, options);
		}
	
		precompose_argv(argc, argv);
		return parse_options_end(&ctx);
	}
