# 后续学习路线

当前项目已经能展示最小链路：

```text
Widget -> RenderObject -> layout -> paint -> pixels -> PPM
```

后续可以按层递进，不要一上来就直接跳到 GPU。下面的顺序更容易建立完整心智模型。

## 1. 加 DisplayList

现在 `paint()` 会直接写像素。

可以改成：

```text
RenderObject.paint()
  -> DisplayList.add(DrawRectCommand)
  -> DisplayList.add(DrawTextCommand)
  -> Rasterizer.rasterize(displayList, pixelCanvas)
```

学习点：

```text
绘制描述和真正光栅化分离
命令可以重放
命令可以调试
命令可以缓存
```

这会更接近 Flutter 的 Picture / DisplayList 思想。

## 2. 加 Element

现在 Widget 直接创建 RenderObject，没有复用。

可以增加：

```text
Widget
Element
RenderObject
```

学习点：

```text
Widget 是配置
Element 是树上的实例
RenderObject 是布局和绘制对象
State 挂在 Element 上
```

这是理解 Flutter 为什么有三棵树的关键。

## 3. 加 dirty 标记和帧调度

现在每次运行只渲染一帧。

可以增加：

```text
markNeedsBuild
markNeedsLayout
markNeedsPaint
scheduleFrame
```

学习点：

```text
不是所有变化都需要重建整棵树
不是所有变化都需要重新布局
不是所有变化都需要重绘全部像素
```

这一步能理解 Flutter 性能模型的核心。

## 4. 加命中测试和事件

可以增加鼠标或简单坐标输入：

```text
hitTest(x, y)
  -> 找到命中的 RenderObject
  -> 分发 PointerEvent
  -> 更新 State
  -> 触发下一帧
```

学习点：

```text
渲染树不只负责画
它也能回答“哪个节点在这个坐标下”
```

## 5. 加裁剪、透明度和变换

可以逐步实现：

```text
clipRect
opacity
translate
scale
rotate
save / restore
```

学习点：

```text
绘制状态栈
局部坐标和全局坐标
为什么复杂效果需要 layer
```

## 6. 加 Layer

在 DisplayList 之后可以增加 Layer Tree：

```text
OffsetLayer
PictureLayer
OpacityLayer
ClipRectLayer
TransformLayer
```

学习点：

```text
RenderObject Tree 和 Layer Tree 不是一回事
某些节点可以缓存成独立图层
合成可以避免重复光栅化
```

这一步会非常接近真实 Flutter 的中段。

## 7. 加 PNG 或窗口输出

PPM 适合教学，但不适合真实使用。

可以有两个方向：

```text
PNG 输出
  学习图片编码和常见图像格式

窗口输出
  学习 Surface、帧循环、输入事件、present
```

如果只是想继续理解渲染，建议先做窗口输出前的 DisplayList 和 Layer，不要太早被平台 API 分散注意力。

## 8. 最后再接 GPU

接 GPU 之前，最好已经有：

```text
DisplayList
Layer Tree
明确的 rasterizer 边界
明确的 frame pipeline
```

然后再把：

```text
CPU Rasterizer
```

替换或并列为：

```text
GPU Rasterizer
```

此时 GPU 只是一个新的后端，而不是把整个架构推倒重来。

## 推荐演进顺序

```text
当前项目
  -> DisplayList
  -> Element + State
  -> dirty 标记
  -> 事件和命中测试
  -> 裁剪/透明度/变换
  -> Layer Tree
  -> 窗口输出
  -> GPU 后端
```

每一步都应该能独立运行，独立观察输出。这样项目会一直保持可学习，而不是变成一团过早复杂化的代码。
