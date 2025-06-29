import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/theme/colors.dart';
import 'package:nota_note/pages/main_page/main_page.dart';

class SharedMainItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final displayTitle =
    title.length > 15 ? '${title.substring(0, 15)}...' : title;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 335,
        height: 64,
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: ShapeDecoration(
          color: AppColors.primary300Main,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: Color(0xFFF0F0F0)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/group_folder_icon.svg',
                  width: 16,
                  height: 16,
                  colorFilter:
                  ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
                SizedBox(width: 8),
                (searchQuery != null &&
                    searchQuery!.isNotEmpty &&
                    title
                        .toLowerCase()
                        .contains(searchQuery!.toLowerCase()))
                    ? _highlightText(displayTitle, searchQuery!)
                    : Text(
                  displayTitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '($noteCount)',
                  style: TextStyle(
                    fontSize: 14,
                    overflow: TextOverflow.ellipsis,
                    color: Colors.white70,
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
          style: TextStyle(color: Colors.white, fontSize: 16),
        ));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(color: Colors.white, fontSize: 16),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
            color: Colors.yellow,
            fontSize: 16,
            fontWeight: FontWeight.bold),
      ));
      start = index + query.length;
    }
    return Text.rich(TextSpan(children: spans));
  }
}