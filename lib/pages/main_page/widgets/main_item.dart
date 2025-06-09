import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/group_viewmodel.dart';

class MainItem extends ConsumerStatefulWidget {
  final String title;
  final String groupId;
  final VoidCallback? onTap;

  const MainItem({
    required this.title,
    required this.groupId,
    this.onTap,
    super.key,
  });

  @override
  ConsumerState<MainItem> createState() => _MainItemState();
}

class _MainItemState extends ConsumerState<MainItem> {
  final TextEditingController _renameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _renameController.text = widget.title;
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  // 그룹 이름 변경 다이얼로그 표시
  void _showRenameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('그룹 이름 변경'),
        content: TextField(
          controller: _renameController,
          decoration: InputDecoration(
            hintText: '새 그룹 이름을 입력하세요',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final newName = _renameController.text.trim();
              if (newName.isNotEmpty) {
                final success = await ref
                    .read(groupViewModelProvider)
                    .renameGroup(widget.groupId, newName);

                if (context.mounted) {
                  Navigator.pop(context);

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('그룹 이름이 변경되었습니다'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    // 에러 메시지 표시
                    final error = ref.read(groupViewModelProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error ?? '이름 변경 실패'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text('변경'),
          ),
        ],
      ),
    );
  }

  // 그룹 삭제 확인 다이얼로그 표시
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('그룹 삭제'),
        content: Text(
          '정말로 "${widget.title}" 그룹을 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없으며, 그룹 내의 모든 노트와 페이지가 삭제됩니다.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final success = await ref
                  .read(groupViewModelProvider)
                  .deleteGroup(widget.groupId);

              if (context.mounted) {
                Navigator.pop(context);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('그룹이 삭제되었습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // 에러 메시지 표시
                  final error = ref.read(groupViewModelProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? '삭제 실패'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => _buildBottomSheet(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? () => _showBottomSheet(context),
      child: Container(
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          color: Color(0xffF4F4F4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/group_folder_icon.png',
                    width: 16,
                    height: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _showBottomSheet(context),
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
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
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
                    child: Text(
                      '공유',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameDialog(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '이름 변경',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmDialog(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '삭제',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
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
