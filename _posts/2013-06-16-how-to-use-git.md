---
layout: post
title: how to use git
---
	
	master=HEAD, stage, workspace, three big parts of git
	
	1. 	git checkout tag : check out a know tag
	2. 	git tag : check the tags of current project
	3. 	git config --global : 	modify "~/.gitconfig" 
				  --local : 	modify "workspace/.git/config
				  --system :	modify "/etc/gitconfig"
				  --unset --global/local/system : "delete the related config"
	4. 	git init dirname : create a repository named dirname
	5. 	git commit --amend para : modify the latest commit
	6. 	git log	--commit : show the file detail changes of the commit
				--pretty=oneline : a oneline log with magic number and log mesg
				--pretty=raw : show a full detail info of a commit record
				--graph : show a tree format of commit
	7. 	git diff 		 : compare workspace with stage 
				--cached : compare stage with repo
				 HEAD	 : compare workspace with repo
	8. 	git reset HEAD : stage will be recovered by master, not affect workspace
	9. 	git checkout -- file : file change in workspace will be covered, stage c
							   content not change
					HEAD <file> : file in stage and workspace all be covered
	10.	git clean -fd : clean all the files and dirs not add to repo. 
	11.	git ls -l HEAD : show HEAD tree
			   -s :		 show stage tree
	12.	git stash : temporily saved the workspace, where will become clean after exec this command
	13. 	git cat-file -t magicnumber : check the type of magic number
					 -p magicnumber : check the content of the magic number
	14.	git clone repo tag
	15. change the default editor: git config --global core.editor "vim"
	16. get the ".git" position: git rev-parse --git-dir
	17. git commit --amend: modify last commit, no commit a new one
	18. how to check out files from a bare repo
		cat .git/packed-refs, checkout the files from the SHA1 hash number
	
	How to get all from ftp server?
	A: wget ftp://xxx.xx7.xxx.xx/* --ftp-user=xxxxxxxxxxxxxxxxxxxx --ftp-password=xxxxxxxx -r
