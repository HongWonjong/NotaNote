import 'package:flutter/material.dart';
import 'package:nota_note/models/widget_model.dart' as widget_model;

class OverlayWidgets extends StatelessWidget {
  final List<widget_model.Widget> widgets;
  final double screenWidth;
  final double screenHeight;

  OverlayWidgets({
    required this.widgets,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: widgets.map((widget) {
        return Positioned(
          left: widget.position['xFactor']! * screenWidth,
          top: widget.position['yFactor']! * screenHeight,
          child: Container(
            width: widget.size['widthFactor']! * screenWidth,
            height: widget.size['heightFactor']! * screenHeight,
            child: widget.type == 'image'
                ? Image.network(widget.content['imageUrl'] ?? '', fit: BoxFit.cover)
                : Text(widget.content['url'] ?? ''),
          ),
        );
      }).toList(),
    );
  }
}