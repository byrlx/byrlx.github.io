---
layout: post
title: User GridView show images
tags: [Android]
---

通过 GridView 显示指定位置的图片.
这个过程的一种方法:

#### 1. Activity

1. 设置 Activity 的 Layout 中包含一个 GridView.
2. 在 onCreate()函数中初始化一个自定义的 Adapter 对象,
并通过 GridView 的 setAdapter() 函数将 View 与 Adpater 绑定.
3. 传给 Adapter 的参数包括:a,context; b,  每个 Item view 的 layout; c, 数组或 ArrayList;

	Adapter adapter = new Adapter(context, layoutId, object[]);
	gridView.setAdapter(adapter);


自动更新.

#### 2. 自定义 Adapter(一般继承自 ArrayAdapter)

1. 重新 getView() 函数, 在该函数里获取 image 的 bitmap 对象,并添加到 imageView 中,然后返回
ImageView 或其父 View.
2. 对于大图片的加载,可以加载缩略图.通过 BitmapFactory 的 decode 函数先获取图片信息,确定需要
缩放的比例,然后再次调用 decode 函数生成缩略图.
3. 图片的缓存可以使用 LruCache 以防止 OOM.
4. 当 object[]中的数据发生变化时,调用 adpater 的notifyDataSetChanged()函数实现 GridView 的
更新

#### 3. 自定义 Adapter 集成 onScrollListener

重新 onScrolStateChanged 和 onScroll()方法来动态加载图片.
