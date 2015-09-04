---
layout: post
title: Copy file from uri
tags: [Android]
---

本文给出一种 Uri 表示的 file copy 到指定位置的方法:

	//get fd from uri
	ParcelFileDescriptor pfd = getContentResolver().openFileDescriptor(uri, "r");
	fd = pfd.getFileDescriptor();

	//do the copy
	InputStream is = new FileInputStream(fd);
	OutputStream os = new FileOutputStream(destFile);
	int readBytes;
	byte[] buf = new byte[4096];
	while((readBytes = is.read(buf)) != -1){
		os.write(buf, 0 ,readBytes);
	}
	os.close();
	is.close();

#### PS: Convert bitmap to file

	File file = new File(destFile);
	FileOutputStream out = new FileOutputStream(file);
	bitmap.compress(Bitmap.CompressFormat.PNG, 100, out);
	out.close();



