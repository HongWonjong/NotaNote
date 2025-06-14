import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class ColorPickerWidget extends StatelessWidget {
  final QuillController controller;
  final VoidCallback onClose;

  ColorPickerWidget({required this.controller, required this.onClose});

  void _applyColor(Color color) {
    final selection = controller.selection;
    if (selection.isValid) {
      controller.formatSelection(Attribute.fromKeyValue('color', '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}'));
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
              onTap: () => _applyColor(Color(0xFFDC2727)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFDC2727),
                  shape: OvalBorder(),
                ),
              ),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => _applyColor(Color(0xFFDC7627)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFDC7627),
                  shape: OvalBorder(),
                ),
              ),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => _applyColor(Color(0xFFDCB527)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFDCB527),
                  shape: OvalBorder(),
                ),
              ),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => _applyColor(Color(0xFF2DA309)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFF2DA309),
                  shape: OvalBorder(),
                ),
              ),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => _applyColor(Color(0xFF1434EA)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFF1434EA),
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