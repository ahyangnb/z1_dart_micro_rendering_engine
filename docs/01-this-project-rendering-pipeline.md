# 本项目渲染流水线

本项目是一条最小可观察的 UI 渲染流水线：

```text
buildDemoApp()
  -> Widget 树
  -> createRenderObject()
  -> RenderObject 树
  -> layout(BoxConstraints)
  -> paint(PixelCanvas)
  -> PixelCanvas._pixels
  -> writePpm()
  -> demo.ppm
```

## 结论

当前项目不是 GPU 渲染，也不是窗口渲染。

它没有这些东西：

```text
Flutter Engine
Skia
Impeller
OpenGL
Metal
Vulkan
Surface
swapchain
系统合成器
真实屏幕刷新
```

它有的是：

```text
List<Color> _pixels
```

`PixelCanvas` 维护一个长度为 `width * height` 的 RGB 像素数组。每次 `drawRect()`、`drawStrokeRect()`、`drawText()`，本质上都是在 CPU 上改这个数组里的颜色。最后 `writePpm()` 把这些 RGB 字节写成 PPM 图片。

## 1. Widget 树

入口在 `main()`：

```dart
runApp(
  buildDemoApp(),
  width: 480,
  height: 300,
  outputPath: outputPath,
  background: const Color.rgb(30, 35, 42),
);
```

`buildDemoApp()` 返回一棵声明式 UI 树：

```text
Center
  Container
    Padding
      Column
        Text
        SizedBox
        Row
          Container
            Center
              Text
          SizedBox
          Column
            Text
            SizedBox
            Text
            SizedBox
            Text
        SizedBox
        Text
```

这一层只描述“想要什么 UI”。它不保存最终尺寸，也不直接写像素。

对应代码概念：

| 本项目 | 含义 |
|--------|------|
| `Widget` | 不可变 UI 配置 |
| `Center` | 描述子节点居中 |
| `Container` | 描述宽高、背景色、边框、子节点 |
| `Row` / `Column` | 描述横向或纵向排列 |
| `Text` | 描述文本内容和颜色 |

## 2. RenderObject 树

`Widget.createRenderObject()` 把声明式配置变成真正工作的渲染对象。

例如：

```dart
class Center extends Widget {
  @override
  RenderObject createRenderObject() {
    return RenderCenter(child.createRenderObject());
  }
}
```

`RenderObject` 才真正拥有：

```text
size
layout()
performLayout()
paint()
```

对应关系：

| Widget | RenderObject |
|--------|--------------|
| `Center` | `RenderCenter` |
| `Padding` | `RenderPadding` |
| `Container` | `RenderContainer` |
| `SizedBox` | `RenderSizedBox` |
| `Row` | `RenderRow` |
| `Column` | `RenderColumn` |
| `Text` | `RenderText` |

真实 Flutter 中间还有 `Element` 层；本项目为了教学把它省掉了。

## 3. Layout 阶段

布局从根节点开始：

```dart
root.layout(BoxConstraints.tight(Size(width.toDouble(), height.toDouble())));
```

根节点拿到的是一个严格约束：

```text
minWidth = 480
maxWidth = 480
minHeight = 300
maxHeight = 300
```

也就是根节点必须是 `480x300`。

布局规则是 Flutter `RenderBox` 模型的核心简化版：

```text
Constraints go down.
Sizes go up.
Parent sets position.
```

中文理解：

```text
约束向下传。
尺寸向上传。
父节点决定子节点位置。
```

几个例子：

| 节点 | 布局行为 |
|------|----------|
| `RenderCenter` | 让子节点在放松后的约束里布局，自己尽量占满父约束 |
| `RenderPadding` | 先扣掉 padding，把缩小后的约束传给子节点 |
| `RenderContainer` | 如果指定了 width/height，就优先使用固定尺寸 |
| `RenderColumn` | 逐个布局子节点，宽度取最大子节点宽度，高度累加 |
| `RenderRow` | 逐个布局子节点，宽度累加，高度取最大子节点高度 |
| `RenderText` | 用 `BitmapFont.measure()` 计算文字占用尺寸 |

## 4. Paint 阶段

布局结束后，每个 `RenderObject` 都已经有自己的 `size`。

然后执行：

```dart
root.paint(canvas, Offset.zero);
```

本项目的 paint 直接画到 `PixelCanvas`，没有中间的 Layer Tree 或 DisplayList。

例如 `RenderContainer.paint()`：

```dart
if (color != null) {
  canvas.drawRect(offset.dx, offset.dy, size.width, size.height, color!);
}
if (border != null) {
  canvas.drawStrokeRect(...);
}
child?.paint(canvas, offset);
```

这里的 `offset` 是当前节点左上角在整张图片里的位置。

## 5. PixelCanvas

`PixelCanvas` 是这个项目里的“玩具版 Skia/Canvas”：

```dart
final List<Color> _pixels;
```

它支持三个绘制操作：

| 方法 | 含义 |
|------|------|
| `drawRect()` | 填充矩形 |
| `drawStrokeRect()` | 画矩形边框 |
| `drawText()` | 用 5x7 点阵字体画文本 |

核心写像素逻辑在 `_fillRect()`：

```dart
for (var py = top; py < bottom; py++) {
  final rowStart = py * width;
  for (var px = left; px < right; px++) {
    _pixels[rowStart + px] = color;
  }
}
```

这就是软件光栅化的最小形态：CPU 循环每个像素，把它设成某个颜色。

## 6. 输出 PPM 图片

最后：

```dart
canvas.writePpm(outputPath);
```

PPM P6 文件格式非常简单：

```text
P6
宽 高
255
RGBRGBRGBRGB...
```

本项目选择 PPM 是为了让输出阶段几乎没有隐藏细节。如果换成 PNG，就还要引入压缩、过滤器、chunk 等额外概念。

## 和真实 Flutter 的差距

| 能力 | 本项目 | 真实 Flutter |
|------|--------|--------------|
| 声明式 Widget | 有 | 有 |
| Element 生命周期 | 无 | 有 |
| RenderObject 布局 | 有，极简 | 有，完整 |
| 文本排版 | 5x7 点阵 | HarfBuzz、字体、段落布局 |
| Paint 命令记录 | 无，直接写像素 | DisplayList / Layer |
| Layer Tree | 无 | 有 |
| Scene 提交 | 无 | 有 |
| GPU 后端 | 无 | Skia / Impeller |
| 窗口 Surface | 无 | 有 |
| 物理屏幕显示 | 无，只输出图片 | 有 |

最重要的学习价值是：你能看清 UI 框架从“组件树”到“像素”的最小骨架。
