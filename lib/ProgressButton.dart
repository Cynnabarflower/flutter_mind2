import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProgressButton extends StatefulWidget {
  Future<dynamic> Function()? onTap;
  Widget? child;
  bool expanded;
  Animation<double> animation;
  num buttonHeight;
  Color? colorExpanded;
  Color? colorShrinked;

  ProgressButton({required this.animation, this.expanded = true, this.colorExpanded, this.colorShrinked, this.onTap, this.child, required this.buttonHeight, key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _ProgressButtonState();
}

class _ProgressButtonState extends State<ProgressButton>
    with SingleTickerProviderStateMixin {
  bool showAnimation = false;

  late var _colorTween = ColorTween(
      begin: widget.colorShrinked ?? Colors.redAccent.shade400,
      end: widget.colorExpanded ?? Colors.lightBlueAccent[100]
  );


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          showAnimation = true;
          setState(() {});
          widget.onTap!().then((value) {
            showAnimation = false;
            setState(() {});
          });
        }
      },
      child: AnimatedBuilder(
        animation: widget.animation,
        builder: (context, child) {
          return LayoutBuilder(builder: (context, constraints) {
            return Material(
              elevation: 10,
              shape: CircleBorder(),
              child: AspectRatio(
                aspectRatio: (constraints.maxWidth/widget.buttonHeight - 1) * (1 - widget.animation.value) + 1,
                child: Container(
                  decoration: BoxDecoration(
                      color: _colorTween.lerp(widget.animation.value),
                      borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(widget.animation.value * 512),
                          right: Radius.circular(widget.animation.value * 500 + 12)
                      )
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    fit: StackFit.expand,
                    children: [
                      if (showAnimation)
                        CircularProgressIndicator(
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue[500]!),
                        ),
                      widget.child ?? Container(),
                    ],
                  ),
                ),
              ),
            );
          },);
        },
      ),
    );
  }
}
