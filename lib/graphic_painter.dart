import 'dart:async';
import 'dart:developer';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class GraphicWidget extends StatefulWidget with ChangeNotifier  {
  List<double> points = [];
  double minPoint = 99999;
  double maxPoint = -99999;
  GlobalKey key;
  bool changeScaleOnPop = false;
  StreamSubscription? subscription;
  late List<int> window = [0, 0, 99];
  var isTrimming = false;
  final _counter = ValueNotifier<int>(0);
  Stream<double>? stream;

  void setStream(Stream<double>? stream) {
    this.stream = stream;
    if (subscription != null) {
      subscription!.cancel();
    }
    if (stream != null) {
      subscription = stream.listen((event) {
        add(event.toDouble());
        if (window[2] != 0 && points.length > window[2]) {
          window[0]++;
          window[1]++;
        } else {
          window[1]++;
        }
      });
    }
  }

  @override
  State createState() => _GraphicWidgetState();

  GraphicWidget(GlobalKey this.key, {this.changeScaleOnPop = false, List<int>? window}) : super(key: key) {
    this.window = window ?? [0, 0, 90];
  }

  bool needsRepaint = true;

  void add(double a) {
    points.add(a);
    if (a < minPoint)
      minPoint = a;
    if (a > maxPoint)
      maxPoint = a;
    _counter.value++;
    // needsRepaint = true;
    // this.key.currentState?.setState(() {});
    // needsRepaint = false;
    //
  }

  void popFirst() {
    if (changeScaleOnPop) {
      // if (points.length > 1) {
      //   if (points[0] <= minPoint) {
      //     minPoint = points[1];
      //     for (int i = 2; i < points.length; i++) {
      //       if (points[i] <= minPoint) {
      //         minPoint = points[i];
      //         break;
      //       }
      //     }
      //   } else if (points[0] >= maxPoint) {
      //     maxPoint = points[1];
      //     for (int i = 2; i < points.length; i++) {
      //       if (points[i] <= maxPoint) {
      //         maxPoint = points[i];
      //         break;
      //       }
      //     }
      //   }
      // } else {
      //   minPoint = 100;
      //   maxPoint = -100;
      // }
      updateMinMax();
    }
    points.removeAt(0);
    notifyListeners();
  }

  void updateMinMax() {
    if (points.isNotEmpty) {
      minPoint = maxPoint = points[window[0]];
      for (var p in points.getRange(window[0], window[1])) {
        minPoint = min(minPoint, p);
        maxPoint = max(maxPoint, p);
      }
      if (minPoint == maxPoint) {
        minPoint -= minPoint * 0.1 + 1;
        maxPoint += maxPoint * 0.1 + 1;
      }
    }
  }

  void clear() {
    points.clear();
    minPoint = maxPoint = 0;
  }
}

class _GraphicWidgetState extends State<GraphicWidget> {
  double _position = 0;
  double lastPosition = 0;
  Size sliderSize = Size(20, 30);
  double sliderValue = 0;
  GlobalKey trimKey = GlobalKey();

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (details.primaryDelta! < 1) {
                    var d = (details.primaryDelta!).floor().abs();
                    widget.window[0] += min(d, widget.points.length - widget.window[1]);
                    widget.window[1] += min(d, widget.points.length - widget.window[1]);
                  } else if (details.primaryDelta! > 1) {
                    var d = -(details.primaryDelta!).floor().abs();
                    widget.window[0] += max(d, -widget.window[0]);
                    widget.window[1] += max(d, -widget.window[0]);
                  }
                  widget.notifyListeners();
                  },
                child: StreamBuilder(
                  stream: widget.stream,
                  builder: (context, snapshot) =>
                  CustomPaint(
                    painter: BackGraphicPainter(widget.points, widget.minPoint, widget.maxPoint, widget.needsRepaint, widget.window),
                    foregroundPainter: GraphicPainter(widget, ValueNotifier(widget._counter)),
                    size: constraints.biggest,
                    willChange: true,
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }



  double getPosition(BoxConstraints constraints) {
    if (_position < 0) {
      return 0;
    } else if (_position > constraints.maxWidth - sliderSize.width) {
      return constraints.maxWidth - sliderSize.width;
    } else {
      return _position;
    }
  }

  void updatePosition(details) {
    if (details is DragStartDetails) {
      lastPosition = (details.globalPosition.dx - details.localPosition.dx) - sliderSize.width/2;
      print('$lastPosition  ${details.localPosition.dx}');
    }
    if (details is DragEndDetails) {
      setState(() {
        // _position =  widget.width - widget.height;
      });
    } else if (details is DragUpdateDetails) {
      setState(() {
        _position = lastPosition + details.localPosition.dx;
      });
    }
    // print('${getPosition()}  ${widget.height}');
  }

}


class BackGraphicPainter extends CustomPainter {

  Paint p = new Paint()
    ..color = Colors.grey;

  List<double> points = [];
  double minPoint = 99999;
  double maxPoint = -99999;
  bool needsRepaint = false;
  List<int> window;

  BackGraphicPainter(this.points, this.minPoint, this.maxPoint, this.needsRepaint, this.window) {
    p.strokeJoin = StrokeJoin.round;
    p.strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    double delta = max(1, maxPoint - minPoint);
    double pointH = size.height / delta;
    p.strokeWidth = 0.5;
    canvas.drawLine(
        new Offset(0, size.height),
        new Offset(size.width, size.height),
        p
    );
    TextPainter(
      text:  TextSpan(text: '${minPoint}', style: TextStyle(color: Colors.grey)),
      textDirection: TextDirection.ltr,
    )
    ..layout(
      minWidth: 0,
      maxWidth: size.width,
    )
      ..paint(canvas, new Offset(size.width-36, size.height-20));

    canvas.drawLine(
        new Offset(0, size.height + (minPoint - maxPoint) * pointH),
        new Offset(size.width, size.height + (minPoint - maxPoint) * pointH),
        p
    );
    canvas.drawLine(
        new Offset(0, size.height + (minPoint - maxPoint)/2 * pointH),
        new Offset(size.width, size.height + (minPoint - maxPoint)/2 * pointH),
        p
    );
    TextPainter(
      text:  TextSpan(text: '${maxPoint}',style: TextStyle(color: Colors.grey)),
      textDirection: TextDirection.ltr,
    )
      ..layout(
        minWidth: 0,
        maxWidth: size.width,
      )
      ..paint(canvas, new Offset(size.width-36, 10));


  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return needsRepaint;
  }

}

class GraphicPainter extends CustomPainter {

  GraphicWidget controller;

  Paint p = new Paint()
  ..color = Colors.green[700]!
    ..style = PaintingStyle.stroke;

  List<double> points = [];
  double minPoint = 99999;
  double maxPoint = -99999;
  bool needsRepaint = false;
  late List<int> window;

  GraphicPainter(this.controller, Listenable valueNotifier) : super(repaint: controller) {
    window = controller.window;
    points = controller.points.sublist(window[0], window[1]);
    minPoint = controller.minPoint;
    maxPoint = controller.maxPoint;
    needsRepaint = controller.needsRepaint;
    p.strokeJoin = StrokeJoin.round;
    p.strokeCap = StrokeCap.round;
  }

  @override
  void paint(Canvas canvas, Size size) {
    double delta = max(1, maxPoint - minPoint);
    // double pointW = (size.width / points.length).floorToDouble();
    double pointW = size.width / points.length;
    double pointH = size.height / delta;
    p.strokeWidth = max(min(pointH, pointW), 0.5);
    // print('painting ${size} ${delta} ${pointH} ${minPoint} ${maxPoint} ${pointW} $pointH ${points.length}');
    var minH = 9999.9;
    Path path = new Path();
    if (points.isNotEmpty) {
      path.moveTo(0, size.height + (minPoint - points[0]) * pointH);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(i * pointW, size.height + (minPoint - points[i]) * pointH);
        // canvas.drawLine(
        //     new Offset( (i-1) * pointW, size.height + (minPoint - points[i-1]) * pointH),
        //     new Offset( i * pointW, size.height + (minPoint - points[i]) * pointH),
        //     p
        // );
        minH = min(size.height + (minPoint - points[i - 1]) * pointH, minH);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}

class SomeWidget extends StatelessWidget {
  GraphicWidget graphicWidget;

  SomeWidget(this.graphicWidget);

  @override
  Widget build(BuildContext context) {
    return new CustomPaint(
      painter: new GraphicPainter(graphicWidget, ValueNotifier(graphicWidget.points)),
      willChange: true,
    );
  }
}