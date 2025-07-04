import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/viewmodels/group_viewmodel.dart';
import 'package:nota_note/widgets/dialogs/rename_group_dialog.dart';
import 'package:nota_note/theme/colors.dart';
import 'package:nota_note/pages/main_page/main_page.dart';

class MainItem extends ConsumerWidget {
  final String title;
  final String groupId;
  final int noteCount;
  final String role;
  final VoidCallback? onTap;
  final String? searchQuery;

  const MainItem({
    Key? key,
    required this.title,
    required this.groupId,
    required this.noteCount,
    required this.role,
    this.onTap,
    this.searchQuery,
  }) : super(key: key);

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    showRenameGroupBottomSheet(
      context: context,
      ref: ref,
      groupId: groupId,
      currentTitle: title,
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('그룹 삭제'),
        content: Text(
          '정말로 "$title" 그룹을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없으며, 그룹 내의 모든 노트와 페이지가 삭제됩니다.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success =
                  await ref.read(groupViewModelProvider).deleteGroup(groupId);

              if (success) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('그룹이 삭제되었습니다'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                final error = ref.read(groupViewModelProvider).error;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(error ?? '삭제 실패'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => _buildBottomSheet(context, ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayTitle =
        title.length > 15 ? '${title.substring(0, 15)}...' : title;

    return GestureDetector(
      onTap: onTap ?? () => _showBottomSheet(context, ref),
      child: Container(
        width: 335,
        height: 64,
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: ShapeDecoration(
          color: Color(0xFFF9F9F9),
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
                      ColorFilter.mode(Color(0xFF60CFB1), BlendMode.srcIn),
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
                          color: Color(0xFF191919),
                        ),
                      ),
                SizedBox(width: 8),
                Text(
                  '($noteCount)',
                  style: TextStyle(
                    fontSize: 14,
                    overflow: TextOverflow.ellipsis,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showBottomSheet(context, ref),
              child: SvgPicture.asset(
                'assets/icons/DotsThree.svg',
                width: 32,
                height: 32,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12),
          Center(
            child: Container(
              width: 59,
              height: 6,
              decoration: BoxDecoration(
                color: Color(0xff494949),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '공유하기',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/icons/share_icon.svg',
                          colorFilter: ColorFilter.mode(
                              Color(0xFF4C4C4C), BlendMode.srcIn),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameDialog(context, ref);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '이름 변경하기',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/icons/edit_icon.svg',
                          colorFilter: ColorFilter.mode(
                              Color(0xFF4C4C4C), BlendMode.srcIn),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmDialog(context, ref);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '삭제하기',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/icons/trash_red_icon.svg',
                          colorFilter:
                              ColorFilter.mode(Colors.red, BlendMode.srcIn),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          style: TextStyle(color: Color(0xFF191919), fontSize: 16),
        ));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(color: Color(0xFF191919), fontSize: 16),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
            color: AppColors.primary300Main,
            fontSize: 16,
            fontWeight: FontWeight.bold),
      ));
      start = index + query.length;
    }
    return Text.rich(TextSpan(children: spans));
  }
}
