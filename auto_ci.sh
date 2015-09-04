#!/bin/sh

cd /Users/LX/LX/openSource/github/luis404_blog
make
git add -A
git ci -m "update"
git push
cd org/launcher
git add -u
git ci -m "update"
