# 真实 Flutter 渲染流水线

真实 Flutter 的链路可以概括为：

```text
Widget
  -> Element
  -> RenderObject
  -> Layer Tree
  -> Scene
  -> Flutter Engine
  -> Skia / Impeller
  -> GPU graphics API
  -> operating system compositor
  -> physical display
```

更直白地说：

```text
Dart 写 UI
  -> Framework 计算布局和绘制结构
  -> Engine 把绘制结构转成底层图形命令
  -> GPU 生成像素
  -> 操作系统合成窗口
  -> 屏幕显示
```

## 1. Widget 不负责渲染

Flutter 里的 `Widget` 是不可变配置对象。

比如：

```dart
Container(
  width: 100,
  height: 100,
  color: Colors.red,
)
```

它只是描述：

```text
我想要一个 100x100 的红色盒子。
```

它不直接布局，也不直接绘制，更不会直接调用 GPU。

## 2. Element 负责挂载和更新

Flutter 会把 Widget 树挂载成 Element 树。

Element 负责：

```text
保存 Widget 在树中的位置
维护 State
管理生命周期
处理 dirty 标记
决定复用还是替换子树
连接 Widget 和 RenderObject
```

当你调用：

```dart
setState(() {});
```

Flutter 通常不会立刻重画屏幕，而是把相关 Element 标记为 dirty，等待下一帧统一 build。

本项目没有 Element，所以每次都是直接：

```text
Widget.createRenderObject()
```

这适合教学，但不适合真实应用。真实框架必须复用状态和渲染对象，否则性能和生命周期都会失控。

## 3. RenderObject 负责布局和绘制

Flutter 里真正接近渲染的是 `RenderObject`。

它主要负责：

```text
layout: 根据约束计算尺寸
paint: 生成绘制命令
hit test: 命中测试
semantics: 无障碍语义
compositing: 决定是否需要独立图层
```

对于常见盒模型，Flutter 使用 `RenderBox`：

```text
父节点传 BoxConstraints
子节点选择 Size
父节点决定子节点 Offset
```

这和本项目里的 `BoxConstraints`、`Size`、`Offset` 是同一类思想。

## 4. Paint 通常不是直接画屏幕

真实 Flutter 的 `paint()` 不是每调用一次就马上把像素写到屏幕。

它更接近于记录绘制命令：

```text
drawRect
drawRRect
drawPath
drawParagraph
drawImage
clipRect
transform
saveLayer
```

这些命令会进入 DisplayList、Picture 或 Layer 相关结构，再组成 Layer Tree。

本项目为了显微镜级学习，省掉了命令记录层：

```text
RenderObject.paint()
  -> PixelCanvas.drawRect()
  -> 直接修改 RGB 数组
```

真实 Flutter 则更像：

```text
RenderObject.paint()
  -> PaintingContext
  -> DisplayList / Picture
  -> Layer Tree
```

## 5. Layer Tree 和 Scene

Layer Tree 是 Flutter Framework 和 Engine 之间非常重要的边界。

它表达的是：

```text
哪些内容可以缓存
哪些内容需要变换
哪些内容需要裁剪
哪些内容需要透明度
哪些内容需要独立合成
最终要提交给 Engine 的场景是什么
```

Framework 最后会通过 `dart:ui` 把 Layer Tree 构造成 `Scene`，提交给 Engine。

简单理解：

```text
RenderObject Tree 是布局和绘制职责树。
Layer Tree 是提交给引擎的合成和绘制结果树。
```

## 6. Flutter Engine

Flutter Engine 主要是 C++ 实现。

它负责：

```text
接收 Dart Framework 提交的 Scene
调度帧
管理平台窗口和 Surface
调用 Skia 或 Impeller
处理文本、图片、平台通道等底层能力
和 iOS、Android、Desktop、Web 平台集成
```

在真实 Flutter 里，Dart Framework 不直接调用 Metal、Vulkan 或 OpenGL。Framework 把场景提交给 Engine，Engine 再使用图形后端完成渲染。

## 7. Skia 和 Impeller

Skia 和 Impeller 都是把高层绘制描述变成底层 GPU 工作的渲染后端。

它们大致做这些事：

```text
解析绘制命令
准备路径、文字、图片、纹理
生成或选择 shader
创建 render pass
向 Metal / Vulkan / OpenGL ES 提交 GPU 命令
把结果画到平台 Surface
```

可以把它们理解为：

```text
Flutter 绘制命令 -> GPU 能执行的命令
```

## 8. GPU 到物理屏幕

GPU 不等于屏幕。

GPU 负责把图形命令光栅化成像素，通常写入某个 framebuffer、texture 或平台 Surface。之后系统合成器会把 Flutter 的 Surface 和其他系统窗口、状态栏、输入法、动画层一起合成。

最终才显示到物理屏幕。

大致链路：

```text
Flutter Engine
  -> 渲染到平台 Surface
  -> Android SurfaceFlinger / iOS WindowServer 等系统合成器
  -> 显示控制器
  -> 物理屏幕
```

所以 Flutter 通常不是把每个 `Button`、`Text`、`Container` 变成原生控件。它更多是自己把整棵 UI 画进一个 Surface，再交给操作系统合成。

## 9. 线程模型的简化理解

真实 Flutter 还有多线程调度。常见概念包括：

| 线程 | 粗略职责 |
|------|----------|
| UI thread | 执行 Dart、build、layout、paint，生成 Layer Tree |
| Raster thread | 把 Layer Tree 光栅化，调用 Skia/Impeller |
| Platform thread | 和平台消息、窗口、插件交互 |
| IO thread | 图片解码、资源加载等辅助工作 |

不用一开始死记线程细节。先抓住核心边界：

```text
UI 线程产出“要画什么”。
Raster 线程负责“真正画出来”。
平台和 GPU 负责“显示到设备”。
```

## 10. 和本项目的一一对应

| 本项目 | 真实 Flutter |
|--------|--------------|
| `Widget` | `Widget` |
| 直接 `createRenderObject()` | `Element` inflate / mount / update |
| `RenderObject` | `RenderObject` / `RenderBox` |
| `BoxConstraints` | `BoxConstraints` |
| `layout()` | Layout phase |
| `paint(PixelCanvas)` | Paint phase |
| `PixelCanvas.commands` | DisplayList / Picture 的教学影子 |
| `List<Color> _pixels` | GPU framebuffer / texture 的教学影子 |
| `writePpm()` | Engine + GPU + Surface + compositor 的极简替代 |

一句话总结：

```text
本项目让你看清 Framework 前半段。
真实 Flutter 在后半段多了 Element 复用、Layer Tree、Engine、GPU 和系统合成。
```
