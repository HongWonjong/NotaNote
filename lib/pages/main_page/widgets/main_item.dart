import 'package:flutter/material.dart';

class MainItem extends StatelessWidget {
  final String title;

  const MainItem({
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xffF4F4F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(title),
    );
  }
}
