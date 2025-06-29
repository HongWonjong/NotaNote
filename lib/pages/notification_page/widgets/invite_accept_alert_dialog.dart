import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/notification_viewmodel.dart';

class InviteAcceptAlertDialog extends StatelessWidget {
  final String invitationId;
  final String groupId;
  final String inviterName;
  final String role;
  final WidgetRef ref;

  const InviteAcceptAlertDialog({
    super.key,
    required this.invitationId,
    required this.groupId,
    required this.inviterName,
    required this.role,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '그룹 초대 안내',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4C4C4C),
              fontSize: 18,
              fontFamily: 'ABeeZee',
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: inviterName,
                  style: const TextStyle(
                    color: Color(0xFF191919),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    height: 1.2,
                  ),
                ),
                const TextSpan(
                  text: '님이',
                  style: TextStyle(
                    color: Color(0xFF191919),
                    fontSize: 16,
                    fontFamily: 'ABeeZee',
                    height: 1.2,
                  ),
                ),
                const TextSpan(
                  text: ' 새 그룹',
                  style: TextStyle(
                    color: Color(0xFF191919),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    height: 1.2,
                  ),
                ),
                const TextSpan(
                  text: '으로 초대했어요.\n요청을 수락할까요?',
                  style: TextStyle(
                    color: Color(0xFF191919),
                    fontSize: 16,
                    fontFamily: 'ABeeZee',
                    height: 1.2,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.only(bottom: 34, left: 36, right: 36),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F0F0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () async {
                  final viewModel = ref.read(notificationViewModelProvider.notifier);
                  final success = await viewModel.declineInvitation(invitationId);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('초대를 거절했습니다.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('초대 거절에 실패했습니다.')),
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text(
                  '거절',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 16,
                    fontFamily: 'ABeeZee',
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF60CFB1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () async {
                  final viewModel = ref.read(notificationViewModelProvider.notifier);
                  final success = await viewModel.acceptInvitation(
                    invitationId,
                    groupId,
                    role,
                  );
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('초대를 수락했습니다.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('초대 수락에 실패했습니다.')),
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text(
                  '수락',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'ABeeZee',
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}