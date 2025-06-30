import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/theme/colors.dart';

class SharedMainItem extends StatelessWidget {
  final String title;
  final String groupId;
  final int noteCount;
  final String role;
  final VoidCallback? onTap;
  final String? searchQuery;

  const SharedMainItem({
    Key? key,
    required this.title,
    required this.groupId,
    required this.noteCount,
    required this.role,
    this.onTap,
    this.searchQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayTitle =
    title.length > 15 ? '${title.substring(0, 15)}...' : title;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 335,
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: ShapeDecoration(
          color: const Color(0xFFF9F9F9),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFF0F0F0)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/group_folder_icon.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primary300Main,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                (searchQuery != null &&
                    searchQuery!.isNotEmpty &&
                    title.toLowerCase().contains(searchQuery!.toLowerCase()))
                    ? _highlightText(displayTitle, searchQuery!)
                    : Text(
                  displayTitle,
                  style: const TextStyle(
                    color: Color(0xFF191919),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    height: 0.09,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '($noteCount)',
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    height: 0.11,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '공유',
                  style: TextStyle(
                    color: Color(0xFF7F7F7F),
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    height: 0.12,
                  ),
                ),
                const SizedBox(width: 4),
                SvgPicture.asset(
                  'assets/icons/Users.svg', // Replace with actual share icon path
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF7F7F7F),
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightText(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: const TextStyle(
            color: Color(0xFF191919),
            fontSize: 16,
            fontFamily: 'Pretendard',
            height: 0.09,
          ),
        ));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: const TextStyle(
            color: Color(0xFF191919),
            fontSize: 16,
            fontFamily: 'Pretendard',
            height: 0.09,
          ),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 16,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.bold,
          height: 0.09,
        ),
      ));
      start = index + query.length;
    }
    return Text.rich(TextSpan(children: spans));
  }
}