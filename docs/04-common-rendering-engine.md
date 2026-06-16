# 常规渲染引擎结构

不同系统的名字不一样，但很多渲染引擎都有相似结构。

```text
Scene / UI / DOM / Game Objects
  -> update
  -> layout or transform
  -> culling
  -> paint or render command generation
  -> display list or render graph
  -> rasterization
  -> compositing
  -> present
```

Flutter、浏览器、游戏引擎、桌面 UI 工具包都能放进这张图里，只是侧重点不同。

## 1. 先有一棵“描述世界”的树

不同领域有不同名字：

| 系统 | 描述结构 |
|------|----------|
| Flutter | Widget Tree / Element Tree / RenderObject Tree |
| 浏览器 | DOM Tree / CSSOM / Render Tree |
| 游戏引擎 | Scene Graph / Entity Component System |
| 传统 GUI | View Tree / Control Tree |
| 本项目 | Widget Tree / RenderObject Tree |

这棵树不一定直接对应屏幕像素。它首先表达的是“世界里有什么”。

## 2. 更新阶段

更新阶段处理：

```text
状态变化
动画时间
输入事件
数据变化
组件重建
节点增删改
```

Flutter 中对应 `setState()`、build、Element dirty 更新。

游戏引擎中对应每帧 `update(deltaTime)`。

本项目目前没有持续帧循环和状态更新，只有一次性构建。

## 3. 布局或空间计算

2D UI 通常需要布局：

```text
父节点给约束
子节点算尺寸
父节点摆位置
```

浏览器会处理 CSS layout，Flutter 处理 RenderObject layout，本项目处理 `BoxConstraints`。

3D 游戏通常不是约束布局，而是空间变换：

```text
local transform
world transform
view transform
projection transform
```

UI 引擎关心的是盒子尺寸和排列，3D 引擎关心的是模型在三维空间里的位置和投影。

## 4. 生成绘制命令

布局结束后，引擎会把“树”转成更适合渲染的命令。

2D UI 里常见命令：

```text
drawRect
drawPath
drawText
drawImage
clip
transform
opacity
```

3D 引擎里常见命令：

```text
draw mesh
bind material
bind texture
set camera
set lights
dispatch compute
```

本项目没有命令缓冲层，`paint()` 直接调用 `PixelCanvas` 写像素。它的 `commands` 列表只是调试日志，不是一个真正可重放、可优化的 DisplayList。

## 5. 光栅化

光栅化就是把几何、路径、文字、图片等绘制描述变成像素。

软件光栅化：

```text
CPU 循环像素
把颜色写入内存数组
```

本项目就是这种：

```dart
_pixels[rowStart + px] = color;
```

GPU 光栅化：

```text
CPU 准备命令
GPU 并行处理顶点和像素
结果写入 framebuffer / texture
```

真实 Flutter 使用 Skia 或 Impeller 走 GPU 后端时，就属于这条路径。

## 6. 合成

合成是把多个已经渲染好的层组合起来。

典型场景：

```text
一个滚动列表层
一个固定导航栏层
一个半透明弹窗层
一个系统输入法层
```

合成可以减少重复绘制，也可以让变换、透明度、裁剪等操作更高效。

Flutter 有 Layer Tree，浏览器也有自己的 compositing layer 体系，操作系统还有最终窗口合成器。

本项目没有合成层。所有东西最后都画进同一个 `_pixels` 数组。

## 7. Present

Present 指把渲染结果提交给显示系统。

真实图形程序通常会有：

```text
back buffer
front buffer
swapchain
vsync
present
```

本项目没有 present。它的“present”是：

```text
writePpm()
```

也就是写文件，而不是显示到屏幕。

## 常见系统对照

| 阶段 | 本项目 | Flutter | 浏览器 | 游戏引擎 |
|------|--------|---------|--------|----------|
| 描述 | Widget | Widget | DOM/CSSOM | Entity/Scene |
| 更新 | 无持续更新 | build/Element | style/recalc | update |
| 布局 | BoxConstraints | RenderObject layout | CSS layout | transform |
| 绘制命令 | paint 直接写 Canvas | paint -> Layer/DisplayList | paint records | render commands |
| 光栅化 | CPU 写 RGB | Skia/Impeller | 浏览器 GPU 栈 | GPU pipeline |
| 合成 | 无 | Layer Tree + OS | compositor layers | render passes |
| 输出 | PPM 文件 | Surface 到屏幕 | Window/Surface | swapchain present |

## 为什么要从软件渲染学起

直接学 GPU 很容易被大量底层名词淹没：

```text
shader
pipeline
descriptor
command buffer
swapchain
render pass
barrier
```

软件渲染样例能先把最本质的问题暴露出来：

```text
UI 树如何变成尺寸？
尺寸如何变成位置？
位置如何变成绘制命令？
绘制命令如何变成像素？
```

这些问题理解清楚后，再看 GPU 只是把“写像素”这件事换成更高性能的硬件流水线。
