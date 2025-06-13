import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/group_viewmodel.dart';

Future<String?> showRenameGroupDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String groupId,
  required String currentTitle,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  String newName = currentTitle;

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('그룹 이름 변경'),
      content: StatefulBuilder(
        builder: (context, setState) {
          return TextField(
            onChanged: (value) => newName = value,
            decoration: InputDecoration(
              hintText: '새 그룹 이름을 입력하세요',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            controller: TextEditingController(text: currentTitle),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, null),  // null 반환 = 취소
          child: Text('취소'),
        ),
        TextButton(
          onPressed: () async {
            if (newName.trim().isNotEmpty && newName.trim() != currentTitle) {
              final success = await ref
                  .read(groupViewModelProvider)
                  .renameGroup(groupId, newName.trim());

              if (success) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('그룹 이름이 변경되었습니다'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(dialogContext, newName.trim());  // 변경된 이름 반환
              } else {
                final error = ref.read(groupViewModelProvider).error;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(error ?? '이름 변경 실패'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } else {
              Navigator.pop(dialogContext, null);  // 취소와 동일하게 처리
            }
          },
          child: Text('변경'),
        ),
      ],
    ),
  );

  return result;  // 성공 시 새 이름, 취소 시 null 반환
}
