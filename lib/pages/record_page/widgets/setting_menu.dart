import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';

class SettingsMenu extends ConsumerWidget {
  final VoidCallback onClose;
  final GlobalKey iconKey;
  final VoidCallback onDeleteSelected;

  const SettingsMenu({
    required this.onClose,
    required this.iconKey,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RenderBox? renderBox =
    iconKey.currentContext?.findRenderObject() as RenderBox?;
    final Offset? iconPosition = renderBox?.localToGlobal(Offset.zero);
    final Size? iconSize = renderBox?.size;

    double top = (iconPosition?.dy ?? 0) + (iconSize?.height ?? 0) - 100;
    double right = MediaQuery.of(context).size.width -
        (iconPosition?.dx ?? 0) -
        (iconSize?.width ?? 0) +
        20;

    return GestureDetector(
      onTap: onClose,
      child: Stack(
        children: [
          Positioned(
            top: top,
            right: right,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 200,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: ShapeDecoration(
                  color: Color(0xFFF0F0F0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MenuItem(
                      icon: SvgPicture.asset(
                        'assets/icons/ArrowsDownUp.svg',
                        color: Colors.black,
                        width: 20,
                        height: 20,
                      ),
                      text: '정렬 기준',
                      textColor: Color(0xFF4C4C4C),
                      onTap: () {
                        onClose();
                      },
                    ),
                    _MenuItem(
                      icon: SvgPicture.asset(
                        'assets/icons/Delete.svg',
                        color: Colors.red,
                        width: 20,
                        height: 20,
                      ),
                      text: '삭제하기',
                      textColor: Color(0xFFFF2F2F),
                      onTap: () {
                        onDeleteSelected();
                        onClose();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final Widget icon;
  final String text;
  final Color textColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.text,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontFamily: 'Pretendard',
                height: 0.09,
              ),
            ),
          ],
        ),
      ),
    );
  }
}