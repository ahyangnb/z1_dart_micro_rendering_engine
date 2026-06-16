# Framework 和 Engine 的边界

学习 Flutter 或任何渲染系统时，最容易混在一起的词是：

```text
框架
引擎
渲染后端
GPU
操作系统
```

它们不是一回事。

## 一张分层图

```text
Application
  你写的业务代码、页面、状态、交互

Framework
  Widget、Element、RenderObject、布局、绘制描述、手势、动画

Engine
  帧调度、Scene 接收、文本/图片底层能力、平台嵌入、渲染后端调用

Rendering Backend
  Skia / Impeller / 自研 renderer

Graphics API
  Metal / Vulkan / OpenGL ES / Direct3D

GPU Driver and GPU
  执行图形命令，生成像素

Operating System Compositor
  合成多个窗口和系统层

Physical Display
  最终发光的屏幕
```

## Framework 做什么

Framework 更靠近开发者。

它通常负责：

```text
声明式组件模型
状态更新
生命周期
diff / reconciliation
布局
绘制命令生成
事件分发
手势识别
动画时间线
无障碍语义
```

Flutter Framework 的典型对象：

```text
Widget
Element
State
RenderObject
BuildOwner
PipelineOwner
PaintingContext
Layer
```

本项目目前覆盖的是 Framework 的一小段：

```text
Widget
RenderObject
BoxConstraints
layout
paint
```

但缺少：

```text
Element
State
dirty 标记
帧调度
Layer Tree
命中测试
手势
动画
语义
```

## Engine 做什么

Engine 更靠近系统和硬件。

它通常负责：

```text
创建和管理窗口 Surface
和平台生命周期集成
接收 Framework 产出的场景
调用渲染后端
管理 GPU 资源
加载和解码图片
处理字体和文本底层能力
处理平台通道
调度 vsync 帧
```

Flutter Engine 不是 Dart Widget 框架本身。它是 Framework 下面的运行和渲染基础设施。

## Rendering Backend 做什么

渲染后端负责把高层绘制操作变成图形 API 能理解的工作。

例如：

```text
drawPath
drawImage
drawParagraph
clip
transform
opacity
```

会被转成更底层的：

```text
纹理
顶点
索引
shader
pipeline state
render pass
command buffer
```

Flutter 常见后端是 Skia 和 Impeller。

## GPU 做什么

GPU 不是 UI 框架，也不是引擎。GPU 是执行图形工作的硬件。

它擅长：

```text
并行处理大量顶点
并行填充大量像素
纹理采样
混合
抗锯齿
运行 shader
```

GPU 不理解 `Widget`、`Container`、`Text` 这些概念。它看到的是图形后端提交的底层命令和数据。

## 操作系统合成器做什么

操作系统合成器负责把多个图层或窗口合成到最终屏幕。

例如手机上可能同时有：

```text
Flutter 应用 Surface
系统状态栏
导航栏
输入法
系统弹窗
其他应用窗口或动画层
```

Flutter 画好自己的 Surface 后，还需要系统合成器把它和其他内容合成起来。

## 本项目放在哪一层

本项目的真实位置是：

```text
Application + 极简 Framework + CPU 软件 Canvas + 图片输出
```

它把下面这些层都替换成了 `PixelCanvas.writePpm()`：

```text
Engine
Rendering Backend
Graphics API
GPU
OS Compositor
Physical Display
```

所以它非常适合学习 UI 框架骨架，但不能代表真实 Flutter 的底层性能路径。

## 一个判断标准

当你看到一个对象时，可以问：

```text
它是在描述 UI 吗？
  多半是 Framework。

它是在调度帧、管理 Surface、连接平台吗？
  多半是 Engine。

它是在把 drawRect/drawPath 变成 GPU 命令吗？
  多半是 Rendering Backend。

它是在执行 shader、填像素、采样纹理吗？
  那是 GPU。

它是在合成多个窗口和系统 UI 吗？
  那是操作系统合成器。
```
