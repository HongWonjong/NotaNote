import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nota_note/theme/colors.dart';

class ColorPickerWidget extends StatelessWidget {
  final QuillController controller;
  final VoidCallback onClose;
  final Function(Color) onColorSelected;
  final Color? selectedColor;

  ColorPickerWidget({
    required this.controller,
    required this.onClose,
    required this.onColorSelected,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
              onTap: () => onColorSelected(Color(0xFFDC2828)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFDC2828),
                  shape: OvalBorder(
                    side: selectedColor?.value == Color(0xFFDC2828).value
                        ? BorderSide(
                      color: AppColors.primary300Main,
                      width: 2,
                    )
                        : BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => onColorSelected(Color(0xFFDC7628)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFDC7628),
                  shape: OvalBorder(
                    side: selectedColor?.value == Color(0xFFDC7628).value
                        ? BorderSide(
                      color: AppColors.primary300Main,
                      width: 2,
                    )
                        : BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => onColorSelected(Color(0xFFDCB528)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFDCB528),
                  shape: OvalBorder(
                    side: selectedColor?.value == Color(0xFFDCB528).value
                        ? BorderSide(
                      color: AppColors.primary300Main,
                      width: 2,
                    )
                        : BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => onColorSelected(Color(0xFF2DA309)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFF2DA309),
                  shape: OvalBorder(
                    side: selectedColor?.value == Color(0xFF2DA309).value
                        ? BorderSide(
                      color: AppColors.primary300Main,
                      width: 2,
                    )
                        : BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => onColorSelected(Color(0xFF1535EA)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFF1535EA),
                  shape: OvalBorder(
                    side: selectedColor?.value == Color(0xFF1535EA).value
                        ? BorderSide(
                      color: AppColors.primary300Main,
                      width: 2,
                    )
                        : BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: () => onColorSelected(Color(0xFF000000)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFF000000),
                  shape: OvalBorder(
                    side: selectedColor?.value == Color(0xFF000000).value
                        ? BorderSide(
                      color: AppColors.primary300Main,
                      width: 2,
                    )
                        : BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}