# 渲染引擎学习文档

这个目录把当前项目、真实 Flutter、常规渲染引擎放在同一张地图里解释。

当前项目的核心定位：

```text
声明式 UI 学习样例
  -> 有 Widget
  -> 有 RenderObject
  -> 有 layout
  -> 有 paint
  -> 有像素缓冲区
  -> 有图片输出
  -> 没有 Element diff
  -> 没有 Layer Tree
  -> 没有 Scene
  -> 没有 GPU
  -> 没有窗口和物理屏幕显示
```

建议阅读顺序：

1. [本项目渲染流水线](01-this-project-rendering-pipeline.md)
2. [真实 Flutter 渲染流水线](02-real-flutter-rendering-pipeline.md)
3. [Framework 和 Engine 的边界](03-framework-vs-engine.md)
4. [常规渲染引擎结构](04-common-rendering-engine.md)
5. [后续学习路线](05-learning-roadmap.md)

读的时候可以一直用这句话校准：

```text
UI 框架负责“描述、状态、布局、绘制命令”。
渲染引擎负责“把绘制命令变成像素”。
GPU 和系统合成器负责“高效把像素送到屏幕”。
```

当前项目把后两层大幅简化了：它没有图形 API，也没有系统窗口，而是直接用 CPU 修改像素数组并写出 PPM 图片。
