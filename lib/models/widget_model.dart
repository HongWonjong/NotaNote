class Widget {
  final String widgetId;
  final int pageIndex;
  final String type;
  final Map<String, dynamic> content;
  final Map<String, double> position;
  final Map<String, double> size;
  final bool isInteractive;

  Widget({
    required this.widgetId,
    required this.pageIndex,
    required this.type,
    required this.content,
    required this.position,
    required this.size,
    this.isInteractive = false,
  });

  factory Widget.fromFirestore(Map<String, dynamic> data, String widgetId) {
    return Widget(
      widgetId: widgetId,
      pageIndex: data['pageIndex'] ?? 0,
      type: data['type'] ?? '',
      content: Map<String, dynamic>.from(data['content'] ?? {}),
      position: Map<String, double>.from(data['position'] ?? {'xFactor': 0.0, 'yFactor': 0.0}),
      size: Map<String, double>.from(data['size'] ?? {'widthFactor': 0.0, 'heightFactor': 0.0}),
      isInteractive: data['isInteractive'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pageIndex': pageIndex,
      'type': type,
      'content': content,
      'position': position,
      'size': size,
      'isInteractive': isInteractive,
    };
  }
}