import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

double fpart(double x) {
  return x - x.floor();
}

double rfpart(double x) {
  return 1 - fpart(x);
}

// Test cases
// vertical lines
// horizontal lines
// zero length lines

void drawLine(Pixels pixels, Offset start, Offset end, Color color) {
  var delta = end - start;
  final steep = delta.dy.abs() > delta.dx.abs();
  // TODO: swap(x0, y0); swap(x1, y1)
  if (steep) {
    print("STEEP!");
    return;
  }
  if (start.dx > end.dx) {
    final tmp = start;
    end = start;
    start = tmp;
    delta = end - start;
  }

  final gradient = delta.dx == 0.0 ? 1.0 : delta.dy / delta.dx;

  // handle first endpoint
  var xEnd = start.dx.round();
  var yEnd = start.dy + gradient * (xEnd - start.dx);
  var xGap = fpart(start.dx + 0.5);
  final xPixel1 = xEnd; // this will be used in the main loop
  final yPixel1 = yEnd.floor();
  // TODO(steep):
  //         plot(ypxl1,   xpxl1, rfpart(yend) * xgap)
  //         plot(ypxl1+1, xpxl1,  fpart(yend) * xgap)

  pixels.plot(xPixel1, yPixel1, color, rfpart(yEnd) * xGap);
  pixels.plot(xPixel1, yPixel1 + 1, color, fpart(yEnd) * xGap);

  // first y-intersection for the main loop.
  var y = yEnd + gradient;

  // handle second endpoint
  xEnd = end.dx.round();
  yEnd = end.dy + gradient * (xEnd - end.dx);
  xGap = fpart(end.dx + 0.5);
  final xPixel2 = xEnd; // this will be used in the main loop
  final yPixel2 = yEnd.floor();
  // TODO(steep):
  //         plot(ypxl2  , xpxl2, rfpart(yend) * xgap)
  //         plot(ypxl2+1, xpxl2,  fpart(yend) * xgap)

  // FIXME: This seems to be drawing too many light pixels.
  pixels.plot(xPixel2, yPixel2, color, rfpart(yEnd) * xGap);
  pixels.plot(xPixel2, yPixel2 + 1, color, fpart(yEnd) * xGap);

  // TODO(steep):
//         for x from xpxl1 + 1 to xpxl2 - 1 do
//            begin
//                 plot(ipart(intery)  , x, rfpart(intery))
//                 plot(ipart(intery)+1, x,  fpart(intery))
//                 intery := intery + gradient
//            end

  for (int x = xPixel1 + 1; x < xPixel2; ++x) {
    final yFloor = y.floor();
    pixels.plot(x, yFloor, color, rfpart(y));
    pixels.plot(x, yFloor + 1, color, fpart(y));
    y += gradient;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var pixels = Pixels.filled(10, 10, Colors.white);
    // const start = Offset(1.2, 2.3);
    // const end = Offset(7.4, 6.6);
    const start = Offset(0.4, 1.0);
    const end = Offset(7.4, 2.0);
    drawLine(pixels, start, end, Colors.blue.shade500);
    return MaterialApp(
      home: PixelView(pixels: pixels, start: start, end: end),
    );
  }
}

class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  @override
  String toString() => '($x, $y)';

  @override
  bool operator ==(other) {
    if (other is! Position) {
      return false;
    }
    return x == other.x && y == other.y;
  }

  @override
  int get hashCode {
    return hashValues(x, y);
  }
}

class Pixels {
  List<List<Color>> _values;

  int get width => _values.length;
  int get height => _values.first.length;

  Color at(int x, int y) => _values[x][y];
  void setColor(int x, int y, Color color) {
    _values[x][y] = color;
  }

  void plot(int x, int y, Color color, double intensity) {
    assert(intensity >= 0.0);
    assert(intensity <= 1.0);
    var value = 1 - intensity;
    _values[x][y] = Color.fromARGB(
      color.alpha,
      (255 * value).round(),
      (255 * value).round(),
      (255 * value).round(),
    );
  }

  factory Pixels.filled(int width, int height, Color color) {
    return Pixels._(List<List<Color>>.generate(
        width, (index) => List<Color>.filled(height, color)));
  }

  Pixels._(this._values);
}

class PixelView extends StatelessWidget {
  const PixelView(
      {Key? key, required this.pixels, required this.start, required this.end})
      : super(key: key);

  final Pixels pixels;
  final Offset start;
  final Offset end;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CustomPaint(painter: PixelsPainter(pixels, start, end)),
      ),
    );
  }
}

class PixelsPainter extends CustomPainter {
  final Pixels pixels;
  final Offset start;
  final Offset end;

  PixelsPainter(this.pixels, this.start, this.end);

  Rect rectForPosition(Position position, Size cell) {
    return Rect.fromLTWH(position.x * cell.width, position.y * cell.height,
        cell.width, cell.height);
  }

  Offset offsetForPosition(Position position, Size cell) {
    return Offset(position.x * cell.width, position.y * cell.height);
  }

  Offset localToCanvas(Offset offset, Size cell) {
    return Offset(offset.dx * cell.width, offset.dy * cell.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize =
        Size(size.width / pixels.width, size.height / pixels.height);
    final paint = Paint();
    paint.style = PaintingStyle.fill;
    paint.isAntiAlias = false;
    for (int i = 0; i < pixels.width; ++i) {
      for (int j = 0; j < pixels.height; ++j) {
        paint.color = pixels.at(i, j);
        canvas.drawRect(rectForPosition(Position(i, j), cellSize), paint);
      }
    }
    // grid
    final gridPaint = Paint();
    gridPaint.color = Colors.black87;
    gridPaint.strokeWidth = 2.0;
    for (int i = 0; i < pixels.width; ++i) {
      canvas.drawLine(offsetForPosition(Position(i, 0), cellSize),
          offsetForPosition(Position(i, pixels.height), cellSize), gridPaint);
    }
    for (int j = 1; j < pixels.height; ++j) {
      canvas.drawLine(offsetForPosition(Position(0, j), cellSize),
          offsetForPosition(Position(pixels.width, j), cellSize), gridPaint);
    }

    // draw dots?
    // draw line
    final linePaint = Paint();
    linePaint.color = Colors.pink.shade500;
    linePaint.strokeWidth = 2.0;
    canvas.drawLine(localToCanvas(start, cellSize),
        localToCanvas(end, cellSize), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}