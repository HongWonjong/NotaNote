import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/group_viewmodel.dart';

Future<String?> showRenameGroupBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String groupId,
  required String currentTitle,
}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final TextEditingController controller = TextEditingController(text: currentTitle);

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 16,
          right: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          '이름 변경하기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        if (controller.text.trim().isNotEmpty &&
                            controller.text.trim() != currentTitle) {
                          final success = await ref
                              .read(groupViewModelProvider)
                              .renameGroup(groupId, controller.text.trim());

                          if (success) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('그룹 이름이 변경되었습니다'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context, controller.text.trim());
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
                          Navigator.pop(context, null);
                        }
                      },
                      child: Text(
                        '완료',
                        style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLength: 20,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '그룹 이름',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${controller.text.length}/20',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                  buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) => null,
                ),
                SizedBox(height: 16),
              ],
            );
          },
        ),
      );
    },
  );

  return result;
}
