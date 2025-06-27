import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/theme/colors.dart';

final selectedHighlightProvider = StateProvider<Color?>((ref) => null);

class HighlightPickerWidget extends ConsumerWidget {
  final QuillController controller;
  final VoidCallback onClose;
  final Function(Color?) onHighlightSelected;

  HighlightPickerWidget({
    required this.controller,
    required this.onClose,
    required this.onHighlightSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedHighlight = ref.watch(selectedHighlightProvider);

    void selectHighlight(Color? color) {
      ref.read(selectedHighlightProvider.notifier).state = color;
      onHighlightSelected(color);
    }

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
              onTap: () => selectHighlight(Color(0xFFF4C0C0)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFF4C0C0),
                  shape: OvalBorder(
                    side: selectedHighlight?.value == Color(0xFFF4C0C0).value
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
              onTap: () => selectHighlight(Color(0xFFF3D3BA)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFF3D3BA),
                  shape: OvalBorder(
                    side: selectedHighlight?.value == Color(0xFFF3D3BA).value
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
              onTap: () => selectHighlight(Color(0xFFEEDC9B)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFEEDC9B),
                  shape: OvalBorder(
                    side: selectedHighlight?.value == Color(0xFFEEDC9B).value
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
              onTap: () => selectHighlight(Color(0xFFC7EBBC)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFC7EBBC),
                  shape: OvalBorder(
                    side: selectedHighlight?.value == Color(0xFFC7EBBC).value
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
              onTap: () => selectHighlight(Color(0xFFCFE4F5)),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  color: Color(0xFFCFE4F5),
                  shape: OvalBorder(
                    side: selectedHighlight?.value == Color(0xFFCFE4F5).value
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
              onTap: () => selectHighlight(null),
              child: Container(
                width: 24,
                height: 24,
                decoration: ShapeDecoration(
                  shape: OvalBorder(
                    side: selectedHighlight == null
                        ? BorderSide(
                      color: AppColors.primary300Main,
                      width: 2,
                    )
                        : BorderSide.none,
                  ),
                ),
                child: SvgPicture.asset(
                  'assets/icons/HighlightCancel.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}