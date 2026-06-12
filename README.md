# 显微镜级自渲染引擎

这个目录是一个最原始级别的“类 Flutter”自渲染引擎学习样例。

它不依赖 Flutter、浏览器、Canvas、Skia 或任何第三方库，而是用纯 Dart 做一条最小渲染流水线：

```text
Widget 树 -> RenderObject 树 -> layout 计算尺寸 -> paint 画到像素缓冲区 -> 写出 PPM 图片
```

它的目标不是性能，也不是完整 UI 框架，而是让你能在显微镜下看清一个声明式 UI 框架最核心的骨架。

## 运行

在项目根目录执行：

```bash
dart run z1_dart_micro_rendering_engine/micro_rendering_engine.dart
```

运行后会生成：

```text
z1_dart_micro_rendering_engine/demo.ppm
```

PPM 是一种非常简单的位图格式，很多图片查看器可以直接打开。它适合教学，因为写文件时几乎不用隐藏细节。

也可以指定输出文件：

```bash
dart run z1_dart_micro_rendering_engine/micro_rendering_engine.dart /tmp/micro_ui.ppm
```

## 它实现了什么

代码里有一组很小的 Widget：

| Widget      | 作用                       |
|-------------|--------------------------|
| `Center`    | 把子节点放到父节点中心              |
| `Padding`   | 给子节点四周留白                 |
| `Container` | 画背景色、边框，并放一个子节点          |
| `Row`       | 横向排列多个子节点                |
| `Column`    | 纵向排列多个子节点                |
| `SizedBox`  | 固定宽高或制造空白                |
| `Text`      | 使用内置 5x7 像素字体画英文、数字和少量符号 |

运行时会依次打印：

1. Widget 树：用户写出来的声明式配置。
2. RenderObject 树：真正负责 layout 和 paint 的对象。
3. Layout 结果：每个节点最终拿到的尺寸。
4. Paint 命令：引擎往像素缓冲区画了哪些东西。
5. 输出图片路径。

## 它和 Flutter 的对应关系

| 这个目录里的代码               | Flutter 里的概念          | 意思                  |
|------------------------|-----------------------|---------------------|
| `Widget`               | `Widget`              | 不可变的 UI 配置          |
| `createRenderObject()` | inflate / mount 的极简替代 | 把配置变成可工作的渲染节点       |
| `RenderObject`         | `RenderObject`        | 真正保存尺寸并执行布局和绘制      |
| `BoxConstraints`       | `BoxConstraints`      | 父节点告诉子节点“你最多/最少能多大” |
| `layout()`             | layout phase          | 自顶向下传约束，自底向上回报尺寸    |
| `paint()`              | paint phase           | 把矩形、边框、文字画到画布上      |
| `PixelCanvas`          | Skia/Canvas 的玩具版      | 保存每一个像素的 RGB 颜色     |
| `writePpm()`           | GPU/窗口系统输出的玩具版        | 把像素写成图片文件           |

## 最小渲染思想

声明式 UI 的重点不是“直接画按钮”，而是先描述树：

```dart
Center(
  child: Container(
    width: 380,
    height: 220,
    child: Padding(
      padding: EdgeInsets.all(18),
      child: Column(
        children: [
          Text('MICRO RENDER ENGINE'),
          SizedBox(height: 14),
          Row(children: [...]),
        ],
      ),
    ),
  ),
)
```

然后引擎自己完成：

```text
父节点给约束 -> 子节点选尺寸 -> 父节点摆位置 -> 画到像素
```

这就是 Flutter、React Native、浏览器布局引擎等系统背后的共同味道。真实系统更复杂，但第一性原理就是这条链路。

## 和真实 Flutter 的差距

这个小引擎刻意没有实现：

- diff 和 Element 生命周期
- 手势、事件、状态更新
- 文本排版、字体加载、中文字体
- 图片解码
- 裁剪、透明度、变换、阴影
- GPU 加速
- 高性能脏区重绘
- 无障碍和输入法

这些不是漏做，而是先不做。第一步先看清楚“一个 UI 树如何自己变成像素”。

## 建议怎么玩

- 改 `buildDemoApp()` 里的组件树，观察 layout 和最终图片如何变化。
- 把 `Column` 改成 `Row`，观察尺寸和位置变化。
- 修改 `Container` 的宽高、背景色、边框。
- 给 `PixelCanvas` 增加 `drawLine()` 或 `drawCircle()`。
- 给 `Text` 增加自动换行，体会文本排版为什么复杂。

## 文件

```text
z1_dart_micro_rendering_engine/
├── README.md
└── micro_rendering_engine.dart
```
