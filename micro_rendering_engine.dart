import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

// 一个显微镜级别的自渲染引擎。
//
// 它模仿 Flutter 最核心的一条链路：
// 1. 用户写 Widget 树。
// 2. Widget 树被展开成 RenderObject 树。
// 3. RenderObject 根据 BoxConstraints 做 layout。
// 4. RenderObject 把自己 paint 到 PixelCanvas。
// 5. PixelCanvas 把 RGB 像素写成 PPM 图片。
//
// 运行：
//   dart run z1_dart_micro_rendering_engine/micro_rendering_engine.dart
//
// 指定输出：
//   dart run z1_dart_micro_rendering_engine/micro_rendering_engine.dart /tmp/ui.ppm

const defaultOutputPath = 'z1_dart_micro_rendering_engine/demo.ppm';

void main(List<String> args) {
  final outputPath = args.isEmpty ? defaultOutputPath : args.first;

  runApp(
    buildDemoApp(),
    width: 480,
    height: 300,
    outputPath: outputPath,
    background: const Color.rgb(30, 35, 42),
  );
}

Widget buildDemoApp() {
  return Center(
    child: Container(
      width: 392,
      height: 226,
      color: const Color.rgb(245, 248, 252),
      border: const Border(color: Color.rgb(54, 78, 104), width: 3),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MICRO RENDER ENGINE',
              style: TextStyle(
                color: Color.rgb(32, 45, 58),
                scale: 3,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 108,
                  height: 82,
                  color: const Color.rgb(102, 182, 155),
                  border: const Border(color: Color.rgb(21, 93, 82), width: 2),
                  child: const Center(
                    child: Text(
                      'PIXEL',
                      style: TextStyle(
                        color: Color.rgb(13, 55, 49),
                        scale: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WIDGET -> RENDER',
                      style: TextStyle(
                        color: Color.rgb(88, 56, 142),
                        scale: 2,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'LAYOUT -> PAINT',
                      style: TextStyle(
                        color: Color.rgb(166, 82, 44),
                        scale: 2,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'PURE DART UI',
                      style: TextStyle(
                        color: Color.rgb(46, 91, 160),
                        scale: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'NO FLUTTER. NO BROWSER. JUST RGB PIXELS.',
              style: TextStyle(
                color: Color.rgb(74, 82, 92),
                scale: 1,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void runApp(
  Widget app, {
  required int width,
  required int height,
  required String outputPath,
  required Color background,
}) {
  print('--- 1. Widget 树：用户写出来的声明式配置 ---');
  print(app.debugDescribe());

  final root = app.createRenderObject();
  print('\n--- 2. RenderObject 树：真正负责 layout 和 paint ---');
  print(root.debugDescribe());

  root.layout(BoxConstraints.tight(Size(width.toDouble(), height.toDouble())));
  print('\n--- 3. Layout 结果：每个节点最后拿到的尺寸 ---');
  print(root.debugLayout());

  final canvas = PixelCanvas(width, height, background);
  root.paint(canvas, Offset.zero);

  print('\n--- 4. Paint 命令小样本：画布收到了什么 ---');
  for (final command in canvas.commands.take(18)) {
    print(command);
  }
  if (canvas.commands.length > 18) {
    print('... 还有 ${canvas.commands.length - 18} 条 paint 命令');
  }

  canvas.writePpm(outputPath);
  print('\n--- 5. 输出 ---');
  print('saved: $outputPath');
  print('image size: ${width}x$height');
}

abstract class Widget {
  const Widget();

  RenderObject createRenderObject();

  List<Widget> get children => const [];

  String get debugName => runtimeType.toString();

  String debugDescribe([String indent = '']) {
    final buffer = StringBuffer()..writeln('$indent$debugName');
    for (final child in children) {
      buffer.writeln(child.debugDescribe('$indent  '));
    }
    return buffer.toString().trimRight();
  }
}

abstract class RenderObject {
  Size size = Size.zero;

  String get debugName => runtimeType.toString();

  List<RenderObject> get children => const [];

  void layout(BoxConstraints constraints) {
    performLayout(constraints);
  }

  void performLayout(BoxConstraints constraints);

  void paint(PixelCanvas canvas, Offset offset);

  String debugDescribe([String indent = '']) {
    final buffer = StringBuffer()..writeln('$indent$debugName');
    for (final child in children) {
      buffer.writeln(child.debugDescribe('$indent  '));
    }
    return buffer.toString().trimRight();
  }

  String debugLayout([String indent = '']) {
    final buffer = StringBuffer()..writeln('$indent$debugName size=$size');
    for (final child in children) {
      buffer.writeln(child.debugLayout('$indent  '));
    }
    return buffer.toString().trimRight();
  }
}

class Size {
  const Size(this.width, this.height);

  static const zero = Size(0, 0);

  final double width;
  final double height;

  @override
  String toString() {
    return '${width.toStringAsFixed(1)}x${height.toStringAsFixed(1)}';
  }
}

class Offset {
  const Offset(this.dx, this.dy);

  static const zero = Offset(0, 0);

  final double dx;
  final double dy;

  Offset translate(double x, double y) => Offset(dx + x, dy + y);
}

class BoxConstraints {
  const BoxConstraints({
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    this.minHeight = 0,
    this.maxHeight = double.infinity,
  });

  factory BoxConstraints.tight(Size size) {
    return BoxConstraints(
      minWidth: size.width,
      maxWidth: size.width,
      minHeight: size.height,
      maxHeight: size.height,
    );
  }

  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  bool get hasBoundedWidth => maxWidth.isFinite;
  bool get hasBoundedHeight => maxHeight.isFinite;

  Size get biggest {
    return Size(
      hasBoundedWidth ? maxWidth : minWidth,
      hasBoundedHeight ? maxHeight : minHeight,
    );
  }

  BoxConstraints loosen() {
    return BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight);
  }

  BoxConstraints deflate(EdgeInsets padding) {
    return BoxConstraints(
      minWidth: math.max(0, minWidth - padding.horizontal).toDouble(),
      maxWidth: _deflatedMax(maxWidth, padding.horizontal),
      minHeight: math.max(0, minHeight - padding.vertical).toDouble(),
      maxHeight: _deflatedMax(maxHeight, padding.vertical),
    );
  }

  Size constrain(Size size) {
    return Size(
      _clampDouble(size.width, minWidth, maxWidth),
      _clampDouble(size.height, minHeight, maxHeight),
    );
  }

  double constrainWidth(double width) {
    return _clampDouble(width, minWidth, maxWidth);
  }

  double constrainHeight(double height) {
    return _clampDouble(height, minHeight, maxHeight);
  }
}

double _deflatedMax(double maxValue, double delta) {
  if (!maxValue.isFinite) return maxValue;
  return math.max(0, maxValue - delta).toDouble();
}

double _clampDouble(double value, double min, double max) {
  final clampedToMin = value < min ? min : value;
  return clampedToMin > max ? max : clampedToMin;
}

class EdgeInsets {
  const EdgeInsets.fromLTRB(this.left, this.top, this.right, this.bottom);

  const EdgeInsets.all(double value)
      : left = value,
        top = value,
        right = value,
        bottom = value;

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get horizontal => left + right;
  double get vertical => top + bottom;
}

class Color {
  const Color.rgb(this.red, this.green, this.blue);

  final int red;
  final int green;
  final int blue;

  String get hex {
    String part(int value) => value.toRadixString(16).padLeft(2, '0');
    return '#${part(red)}${part(green)}${part(blue)}';
  }
}

class Border {
  const Border({required this.color, this.width = 1});

  final Color color;
  final int width;
}

class TextStyle {
  const TextStyle({
    this.color = const Color.rgb(20, 20, 20),
    this.scale = 2,
  });

  final Color color;
  final int scale;
}

class Center extends Widget {
  const Center({required this.child});

  final Widget child;

  @override
  List<Widget> get children => [child];

  @override
  RenderObject createRenderObject() {
    return RenderCenter(child.createRenderObject());
  }
}

class RenderCenter extends RenderObject {
  RenderCenter(this.child);

  final RenderObject child;

  @override
  List<RenderObject> get children => [child];

  @override
  void performLayout(BoxConstraints constraints) {
    child.layout(constraints.loosen());
    size = constraints.hasBoundedWidth && constraints.hasBoundedHeight
        ? constraints.biggest
        : constraints.constrain(child.size);
  }

  @override
  void paint(PixelCanvas canvas, Offset offset) {
    final childOffset = offset.translate(
      (size.width - child.size.width) / 2,
      (size.height - child.size.height) / 2,
    );
    child.paint(canvas, childOffset);
  }
}

class Padding extends Widget {
  const Padding({
    required this.padding,
    required this.child,
  });

  final EdgeInsets padding;
  final Widget child;

  @override
  List<Widget> get children => [child];

  @override
  RenderObject createRenderObject() {
    return RenderPadding(padding, child.createRenderObject());
  }
}

class RenderPadding extends RenderObject {
  RenderPadding(this.padding, this.child);

  final EdgeInsets padding;
  final RenderObject child;

  @override
  List<RenderObject> get children => [child];

  @override
  void performLayout(BoxConstraints constraints) {
    child.layout(constraints.deflate(padding));
    size = constraints.constrain(
      Size(
        child.size.width + padding.horizontal,
        child.size.height + padding.vertical,
      ),
    );
  }

  @override
  void paint(PixelCanvas canvas, Offset offset) {
    child.paint(canvas, offset.translate(padding.left, padding.top));
  }
}

class Container extends Widget {
  const Container({
    this.width,
    this.height,
    this.color,
    this.border,
    this.child,
  });

  final double? width;
  final double? height;
  final Color? color;
  final Border? border;
  final Widget? child;

  @override
  List<Widget> get children => child == null ? const [] : [child!];

  @override
  RenderObject createRenderObject() {
    return RenderContainer(
      width: width,
      height: height,
      color: color,
      border: border,
      child: child?.createRenderObject(),
    );
  }
}

class RenderContainer extends RenderObject {
  RenderContainer({
    required this.width,
    required this.height,
    required this.color,
    required this.border,
    required this.child,
  });

  final double? width;
  final double? height;
  final Color? color;
  final Border? border;
  final RenderObject? child;

  @override
  List<RenderObject> get children => child == null ? const [] : [child!];

  @override
  void performLayout(BoxConstraints constraints) {
    final childConstraints = BoxConstraints(
      maxWidth: width ?? constraints.maxWidth,
      maxHeight: height ?? constraints.maxHeight,
    );

    if (child != null) {
      child!.layout(childConstraints.loosen());
    }

    size = constraints.constrain(
      Size(
        width ?? child?.size.width ?? constraints.minWidth,
        height ?? child?.size.height ?? constraints.minHeight,
      ),
    );
  }

  @override
  void paint(PixelCanvas canvas, Offset offset) {
    if (color != null) {
      canvas.drawRect(offset.dx, offset.dy, size.width, size.height, color!);
    }
    if (border != null) {
      canvas.drawStrokeRect(
        offset.dx,
        offset.dy,
        size.width,
        size.height,
        border!.color,
        border!.width,
      );
    }
    child?.paint(canvas, offset);
  }
}

class SizedBox extends Widget {
  const SizedBox({
    this.width,
    this.height,
    this.child,
  });

  final double? width;
  final double? height;
  final Widget? child;

  @override
  List<Widget> get children => child == null ? const [] : [child!];

  @override
  RenderObject createRenderObject() {
    return RenderSizedBox(
      width: width,
      height: height,
      child: child?.createRenderObject(),
    );
  }
}

class RenderSizedBox extends RenderObject {
  RenderSizedBox({
    required this.width,
    required this.height,
    required this.child,
  });

  final double? width;
  final double? height;
  final RenderObject? child;

  @override
  List<RenderObject> get children => child == null ? const [] : [child!];

  @override
  void performLayout(BoxConstraints constraints) {
    if (child != null) {
      child!.layout(
        BoxConstraints(
          minWidth: width ?? 0,
          maxWidth: width ?? constraints.maxWidth,
          minHeight: height ?? 0,
          maxHeight: height ?? constraints.maxHeight,
        ),
      );
    }

    size = constraints.constrain(
      Size(
        width ?? child?.size.width ?? 0,
        height ?? child?.size.height ?? 0,
      ),
    );
  }

  @override
  void paint(PixelCanvas canvas, Offset offset) {
    child?.paint(canvas, offset);
  }
}

enum CrossAxisAlignment {
  start,
  center,
  end,
  stretch,
}

class Column extends Widget {
  const Column({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 0,
  });

  @override
  final List<Widget> children;

  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  @override
  RenderObject createRenderObject() {
    return RenderColumn(
      children.map((child) => child.createRenderObject()).toList(),
      crossAxisAlignment: crossAxisAlignment,
      spacing: spacing,
    );
  }
}

class RenderColumn extends RenderObject {
  RenderColumn(
    this._children, {
    required this.crossAxisAlignment,
    required this.spacing,
  });

  final List<RenderObject> _children;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  @override
  List<RenderObject> get children => _children;

  @override
  void performLayout(BoxConstraints constraints) {
    var height = 0.0;
    var width = 0.0;

    for (var i = 0; i < _children.length; i++) {
      final childConstraints =
          crossAxisAlignment == CrossAxisAlignment.stretch &&
                  constraints.hasBoundedWidth
              ? BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                  maxHeight: constraints.maxHeight,
                )
              : BoxConstraints(maxWidth: constraints.maxWidth);

      final child = _children[i];
      child.layout(childConstraints);
      width = math.max(width, child.size.width).toDouble();
      height += child.size.height;
      if (i != _children.length - 1) height += spacing;
    }

    size = constraints.constrain(Size(width, height));
  }

  @override
  void paint(PixelCanvas canvas, Offset offset) {
    var y = offset.dy;
    for (var i = 0; i < _children.length; i++) {
      final child = _children[i];
      var x = offset.dx;
      if (crossAxisAlignment == CrossAxisAlignment.center) {
        x += (size.width - child.size.width) / 2;
      } else if (crossAxisAlignment == CrossAxisAlignment.end) {
        x += size.width - child.size.width;
      }
      child.paint(canvas, Offset(x, y));
      y += child.size.height;
      if (i != _children.length - 1) y += spacing;
    }
  }
}

class Row extends Widget {
  const Row({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 0,
  });

  @override
  final List<Widget> children;

  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  @override
  RenderObject createRenderObject() {
    return RenderRow(
      children.map((child) => child.createRenderObject()).toList(),
      crossAxisAlignment: crossAxisAlignment,
      spacing: spacing,
    );
  }
}

class RenderRow extends RenderObject {
  RenderRow(
    this._children, {
    required this.crossAxisAlignment,
    required this.spacing,
  });

  final List<RenderObject> _children;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  @override
  List<RenderObject> get children => _children;

  @override
  void performLayout(BoxConstraints constraints) {
    var width = 0.0;
    var height = 0.0;

    for (var i = 0; i < _children.length; i++) {
      final childConstraints =
          crossAxisAlignment == CrossAxisAlignment.stretch &&
                  constraints.hasBoundedHeight
              ? BoxConstraints(
                  maxWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight,
                  maxHeight: constraints.maxHeight,
                )
              : BoxConstraints(maxHeight: constraints.maxHeight);

      final child = _children[i];
      child.layout(childConstraints);
      width += child.size.width;
      height = math.max(height, child.size.height).toDouble();
      if (i != _children.length - 1) width += spacing;
    }

    size = constraints.constrain(Size(width, height));
  }

  @override
  void paint(PixelCanvas canvas, Offset offset) {
    var x = offset.dx;
    for (var i = 0; i < _children.length; i++) {
      final child = _children[i];
      var y = offset.dy;
      if (crossAxisAlignment == CrossAxisAlignment.center) {
        y += (size.height - child.size.height) / 2;
      } else if (crossAxisAlignment == CrossAxisAlignment.end) {
        y += size.height - child.size.height;
      }
      child.paint(canvas, Offset(x, y));
      x += child.size.width;
      if (i != _children.length - 1) x += spacing;
    }
  }
}

class Text extends Widget {
  const Text(
    this.data, {
    this.style = const TextStyle(),
  });

  final String data;
  final TextStyle style;

  @override
  RenderObject createRenderObject() {
    return RenderText(data, style);
  }
}

class RenderText extends RenderObject {
  RenderText(this.data, this.style);

  final String data;
  final TextStyle style;

  @override
  void performLayout(BoxConstraints constraints) {
    size = constraints.constrain(BitmapFont.measure(data, style.scale));
  }

  @override
  void paint(PixelCanvas canvas, Offset offset) {
    canvas.drawText(data, offset.dx, offset.dy, style.color, style.scale);
  }
}

class PixelCanvas {
  PixelCanvas(this.width, this.height, Color background)
      : _pixels = List<Color>.filled(width * height, background) {
    commands.add('clear ${width}x$height ${background.hex}');
  }

  final int width;
  final int height;
  final List<Color> _pixels;
  final List<String> commands = [];

  void drawRect(double x, double y, double w, double h, Color color) {
    commands.add(
      'drawRect x=${x.toStringAsFixed(1)} y=${y.toStringAsFixed(1)} '
      'w=${w.toStringAsFixed(1)} h=${h.toStringAsFixed(1)} color=${color.hex}',
    );
    _fillRect(x, y, w, h, color);
  }

  void drawStrokeRect(
    double x,
    double y,
    double w,
    double h,
    Color color,
    int strokeWidth,
  ) {
    commands.add(
      'drawStrokeRect x=${x.toStringAsFixed(1)} y=${y.toStringAsFixed(1)} '
      'w=${w.toStringAsFixed(1)} h=${h.toStringAsFixed(1)} '
      'stroke=$strokeWidth color=${color.hex}',
    );

    final sw = strokeWidth.toDouble();
    _fillRect(x, y, w, sw, color);
    _fillRect(x, y + h - sw, w, sw, color);
    _fillRect(x, y, sw, h, color);
    _fillRect(x + w - sw, y, sw, h, color);
  }

  void drawText(String text, double x, double y, Color color, int scale) {
    commands.add(
      'drawText "$text" x=${x.toStringAsFixed(1)} '
      'y=${y.toStringAsFixed(1)} scale=$scale color=${color.hex}',
    );

    var penY = y;
    for (final line in text.split('\n')) {
      var penX = x;
      for (final rune in line.runes) {
        final char = String.fromCharCode(rune).toUpperCase();
        final glyph = BitmapFont.glyph(char);
        if (char == ' ') {
          penX += BitmapFont.spaceWidth * scale;
          continue;
        }

        for (var row = 0; row < glyph.length; row++) {
          final pattern = glyph[row];
          for (var col = 0; col < pattern.length; col++) {
            if (pattern[col] == '1') {
              _fillRect(
                penX + col * scale,
                penY + row * scale,
                scale.toDouble(),
                scale.toDouble(),
                color,
              );
            }
          }
        }
        penX += (BitmapFont.glyphWidth + BitmapFont.letterGap) * scale;
      }
      penY += (BitmapFont.glyphHeight + BitmapFont.lineGap) * scale;
    }
  }

  void writePpm(String path) {
    final file = File(path);
    file.parent.createSync(recursive: true);

    final bytes = BytesBuilder();
    bytes.add(ascii.encode('P6\n$width $height\n255\n'));
    for (final pixel in _pixels) {
      bytes.add([pixel.red, pixel.green, pixel.blue]);
    }
    file.writeAsBytesSync(bytes.takeBytes());
  }

  void _fillRect(double x, double y, double w, double h, Color color) {
    final left = math.max(0, x.floor());
    final top = math.max(0, y.floor());
    final right = math.min(width, (x + w).ceil());
    final bottom = math.min(height, (y + h).ceil());

    for (var py = top; py < bottom; py++) {
      final rowStart = py * width;
      for (var px = left; px < right; px++) {
        _pixels[rowStart + px] = color;
      }
    }
  }
}

class BitmapFont {
  static const glyphWidth = 5;
  static const glyphHeight = 7;
  static const letterGap = 1;
  static const lineGap = 1;
  static const spaceWidth = 4;

  static Size measure(String text, int scale) {
    final lines = text.split('\n');
    var maxWidth = 0;

    for (final line in lines) {
      var lineWidth = 0;
      for (final rune in line.runes) {
        final char = String.fromCharCode(rune);
        if (char == ' ') {
          lineWidth += spaceWidth * scale;
        } else {
          lineWidth += (glyphWidth + letterGap) * scale;
        }
      }
      if (lineWidth > 0) lineWidth -= letterGap * scale;
      maxWidth = math.max(maxWidth, lineWidth);
    }

    final height = lines.length * glyphHeight * scale +
        (lines.length - 1) * lineGap * scale;
    return Size(maxWidth.toDouble(), height.toDouble());
  }

  static List<String> glyph(String char) {
    return _glyphs[char] ?? _glyphs['?']!;
  }

  static const Map<String, List<String>> _glyphs = {
    'A': [
      '01110',
      '10001',
      '10001',
      '11111',
      '10001',
      '10001',
      '10001',
    ],
    'B': [
      '11110',
      '10001',
      '10001',
      '11110',
      '10001',
      '10001',
      '11110',
    ],
    'C': [
      '01111',
      '10000',
      '10000',
      '10000',
      '10000',
      '10000',
      '01111',
    ],
    'D': [
      '11110',
      '10001',
      '10001',
      '10001',
      '10001',
      '10001',
      '11110',
    ],
    'E': [
      '11111',
      '10000',
      '10000',
      '11110',
      '10000',
      '10000',
      '11111',
    ],
    'F': [
      '11111',
      '10000',
      '10000',
      '11110',
      '10000',
      '10000',
      '10000',
    ],
    'G': [
      '01111',
      '10000',
      '10000',
      '10111',
      '10001',
      '10001',
      '01111',
    ],
    'H': [
      '10001',
      '10001',
      '10001',
      '11111',
      '10001',
      '10001',
      '10001',
    ],
    'I': [
      '11111',
      '00100',
      '00100',
      '00100',
      '00100',
      '00100',
      '11111',
    ],
    'J': [
      '00111',
      '00010',
      '00010',
      '00010',
      '10010',
      '10010',
      '01100',
    ],
    'K': [
      '10001',
      '10010',
      '10100',
      '11000',
      '10100',
      '10010',
      '10001',
    ],
    'L': [
      '10000',
      '10000',
      '10000',
      '10000',
      '10000',
      '10000',
      '11111',
    ],
    'M': [
      '10001',
      '11011',
      '10101',
      '10101',
      '10001',
      '10001',
      '10001',
    ],
    'N': [
      '10001',
      '11001',
      '10101',
      '10011',
      '10001',
      '10001',
      '10001',
    ],
    'O': [
      '01110',
      '10001',
      '10001',
      '10001',
      '10001',
      '10001',
      '01110',
    ],
    'P': [
      '11110',
      '10001',
      '10001',
      '11110',
      '10000',
      '10000',
      '10000',
    ],
    'Q': [
      '01110',
      '10001',
      '10001',
      '10001',
      '10101',
      '10010',
      '01101',
    ],
    'R': [
      '11110',
      '10001',
      '10001',
      '11110',
      '10100',
      '10010',
      '10001',
    ],
    'S': [
      '01111',
      '10000',
      '10000',
      '01110',
      '00001',
      '00001',
      '11110',
    ],
    'T': [
      '11111',
      '00100',
      '00100',
      '00100',
      '00100',
      '00100',
      '00100',
    ],
    'U': [
      '10001',
      '10001',
      '10001',
      '10001',
      '10001',
      '10001',
      '01110',
    ],
    'V': [
      '10001',
      '10001',
      '10001',
      '10001',
      '10001',
      '01010',
      '00100',
    ],
    'W': [
      '10001',
      '10001',
      '10001',
      '10101',
      '10101',
      '11011',
      '10001',
    ],
    'X': [
      '10001',
      '10001',
      '01010',
      '00100',
      '01010',
      '10001',
      '10001',
    ],
    'Y': [
      '10001',
      '10001',
      '01010',
      '00100',
      '00100',
      '00100',
      '00100',
    ],
    'Z': [
      '11111',
      '00001',
      '00010',
      '00100',
      '01000',
      '10000',
      '11111',
    ],
    '0': [
      '01110',
      '10001',
      '10011',
      '10101',
      '11001',
      '10001',
      '01110',
    ],
    '1': [
      '00100',
      '01100',
      '00100',
      '00100',
      '00100',
      '00100',
      '01110',
    ],
    '2': [
      '01110',
      '10001',
      '00001',
      '00010',
      '00100',
      '01000',
      '11111',
    ],
    '3': [
      '11110',
      '00001',
      '00001',
      '01110',
      '00001',
      '00001',
      '11110',
    ],
    '4': [
      '00010',
      '00110',
      '01010',
      '10010',
      '11111',
      '00010',
      '00010',
    ],
    '5': [
      '11111',
      '10000',
      '10000',
      '11110',
      '00001',
      '00001',
      '11110',
    ],
    '6': [
      '01110',
      '10000',
      '10000',
      '11110',
      '10001',
      '10001',
      '01110',
    ],
    '7': [
      '11111',
      '00001',
      '00010',
      '00100',
      '01000',
      '01000',
      '01000',
    ],
    '8': [
      '01110',
      '10001',
      '10001',
      '01110',
      '10001',
      '10001',
      '01110',
    ],
    '9': [
      '01110',
      '10001',
      '10001',
      '01111',
      '00001',
      '00001',
      '01110',
    ],
    '.': [
      '00000',
      '00000',
      '00000',
      '00000',
      '00000',
      '01100',
      '01100',
    ],
    ',': [
      '00000',
      '00000',
      '00000',
      '00000',
      '01100',
      '01100',
      '01000',
    ],
    ':': [
      '00000',
      '01100',
      '01100',
      '00000',
      '01100',
      '01100',
      '00000',
    ],
    '-': [
      '00000',
      '00000',
      '00000',
      '11111',
      '00000',
      '00000',
      '00000',
    ],
    '>': [
      '10000',
      '01000',
      '00100',
      '00010',
      '00100',
      '01000',
      '10000',
    ],
    '?': [
      '01110',
      '10001',
      '00001',
      '00010',
      '00100',
      '00000',
      '00100',
    ],
  };
}
