import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class HighlightPickerWidget extends StatelessWidget {
  final QuillController controller;
  final VoidCallback onClose;

  HighlightPickerWidget({required this.controller, required this.onClose});

  void _applyHighlight(Color color) {
    final selection = controller.selection;
    if (selection.isValid) {
      controller.formatSelection(Attribute.fromKeyValue('background', '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}'));
    }
    // onClose() 호출 제거: 색상 선택 후 UI 유지
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 232,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: ShapeDecoration(
          color: Color(0xFFF0F0F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _applyHighlight(Color(0xFFF4C0C0)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFF4C0C0),
                  shape: OvalBorder(),
                ),
              ),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => _applyHighlight(Color(0xFFF2D2B9)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFF2D2B9),
                  shape: OvalBorder(),
                ),
              ),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => _applyHighlight(Color(0xFFEEDC9A)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFEEDC9A),
                  shape: OvalBorder(),
                ),
              ),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => _applyHighlight(Color(0xFFC6EBBB)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFC6EBBB),
                  shape: OvalBorder(),
                ),
              ),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => _applyHighlight(Color(0xFFD7DDF2)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFD7DDF2),
                  shape: OvalBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}