import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/group_viewmodel.dart';

class MainItem extends ConsumerWidget {
  final String title;
  final String groupId;
  final VoidCallback? onTap;

  const MainItem({
    required this.title,
    required this.groupId,
    this.onTap,
    super.key,
  });

  // 그룹 이름 변경 다이얼로그 표시
  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    // ScaffoldMessenger 미리 가져오기
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // StatefulBuilder를 사용하여 다이얼로그 내부에서 상태 관리
    String newName = title; // 현재 이름으로 초기화

    print('[MainItem] 이름 변경 다이얼로그 표시: 그룹ID=$groupId, 현재이름=$title');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('그룹 이름 변경'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return TextField(
              // 컨트롤러를 사용하지 않고 onChanged로 값 관리
              onChanged: (value) {
                newName = value;
              },
              decoration: InputDecoration(
                hintText: '새 그룹 이름을 입력하세요',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              // 초기값 설정
              controller: TextEditingController(text: title),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              if (newName.trim().isNotEmpty && newName.trim() != title) {
                print('[MainItem] 이름 변경 시도: $newName');

                Navigator.pop(dialogContext); // 먼저 다이얼로그 닫기

                print('[MainItem] 유효한 이름, 뷰모델 renameGroup 호출');
                final success = await ref
                    .read(groupViewModelProvider)
                    .renameGroup(groupId, newName.trim());

                print('[MainItem] 이름 변경 결과: $success');

                if (success) {
                  print('[MainItem] 이름 변경 성공 메시지 표시');
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('그룹 이름이 변경되었습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // 에러 메시지 표시
                  final error = ref.read(groupViewModelProvider).error;
                  print('[MainItem] 이름 변경 실패 메시지 표시: $error');
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(error ?? '이름 변경 실패'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                print('[MainItem] 이름 변경 없음: $newName');
                Navigator.pop(dialogContext);
              }
            },
            child: Text('변경'),
          ),
        ],
      ),
    );
  }

  // 그룹 삭제 확인 다이얼로그 표시
  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    // 컨텍스트 안전하게 사용하기 위해 ScaffoldMessenger 미리 가져오기
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
              Navigator.pop(dialogContext); // 먼저 다이얼로그 닫기

              // final success =
              //     await ref.read(groupViewModelProvider).deleteGroup(groupId);

              // if (success) {
              //   scaffoldMessenger.showSnackBar(
              //     SnackBar(
              //       content: Text('그룹이 삭제되었습니다'),
              //       backgroundColor: Colors.green,
              //     ),
              //   );
              // } else {
              //   // 에러 메시지 표시
              //   final error = ref.read(groupViewModelProvider).error;
              //   scaffoldMessenger.showSnackBar(
              //     SnackBar(
              //       content: Text(error ?? '삭제 실패'),
              //       backgroundColor: Colors.red,
              //     ),
              //   );
              // }
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
          color: Color(0xffF4F4F4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Image.asset(
                    'assets/group_folder_icon.png',
                    width: 16,
                    height: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                    ),
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
                    _showRenameDialog(context, ref);
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
                    _showDeleteConfirmDialog(context, ref);
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
