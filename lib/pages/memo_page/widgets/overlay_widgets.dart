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
          child: IgnorePointer(
            ignoring: !widget.isInteractive,
            child: GestureDetector(
              onTap: widget.isInteractive
                  ? () {
                print('Tapped ${widget.type} at ${widget.position}');
              }
                  : null,
              onPanUpdate: widget.isInteractive && widget.type == 'image'
                  ? (details) {
              }
                  : null,
              child: Container(
                width: widget.size['widthFactor']! * screenWidth,
                height: widget.size['heightFactor']! * screenHeight,
                child: _buildWidgetContent(widget),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWidgetContent(widget_model.Widget widget) {
    switch (widget.type) {
      case 'image':
        return Image.network(
          widget.content['imageUrl'] ?? '',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
        );
      case 'code':
        return Container(
          padding: EdgeInsets.all(8.0),
          color: Colors.grey[200],
          child: Text(
            widget.content['code'] ?? '',
            style: TextStyle(fontFamily: 'monospace', fontSize: 14.0),
          ),
        );
      case 'emoji':
        return Text(
          widget.content['emoji'] ?? '',
          style: TextStyle(fontSize: widget.size['heightFactor']! * screenHeight * 0.8),
        );
      default:
        return Text(widget.content['url'] ?? '');
    }
  }
}