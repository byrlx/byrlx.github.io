---
layout: default
title: Useful adb cmd line
---

{{page.title}}
-------------------
	
	1. service call phone 2 s16 "phone num" : call "phone num"
	                      1                 : dial, not call
	                      5                 : end call
	                      6                 : answer call
	                      7                 : silent ring
	                      13                : cancel notification
	
	2. am broadcast -a android.intent.action.SENDTO -d sms:num --es sms_body "content" : send sms
	
	3. service call isms 5 s16 "dest num" s16 "null" s16 "msg" s16 "null" s16 "null"
	
	4. adb shell date -s "yyyymmdd.[[[hh]mm]ss]"
