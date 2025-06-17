import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/viewmodels/group_viewmodel.dart';
import 'package:nota_note/widgets/dialogs/rename_group_dialog.dart';


class MainItem extends ConsumerWidget {
  final String title;
  final String groupId;
  final int noteCount;
  final VoidCallback? onTap;

  const MainItem({
    required this.title,
    required this.groupId,
    required this.noteCount,
    this.onTap,
    super.key,
  });

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
    return GestureDetector(
      onTap: onTap ?? () => _showBottomSheet(context, ref),
      child: Container(
        width: double.infinity,
        height: 72,
        decoration: BoxDecoration(
          color: Color(0xffFAFAFA),
          border: Border(
            bottom: BorderSide(
              color: Color(0xffEFEFEF),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/group_folder_icon.svg',
                    width: 16,
                    height: 16,
                    colorFilter:
                        ColorFilter.mode(Color(0xFF60CFB1), BlendMode.srcIn),
                  ),
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '($noteCount)',
                    style: TextStyle(fontSize: 14, color: Color(0xff999999)),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showBottomSheet(context, ref),
              icon: Icon(
                Icons.more_horiz,
                size: 24,
              ),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
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
                        )
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
                        )
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
                        )
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
}
