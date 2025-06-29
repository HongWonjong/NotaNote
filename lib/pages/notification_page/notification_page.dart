import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:nota_note/viewmodels/auth/user_id_provider.dart';
import 'package:nota_note/viewmodels/notification_viewmodel.dart';
import 'widgets/invite_accept_alert_dialog.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);

    if (userId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('알림')),
        body: const Center(child: Text('로그인이 필요합니다.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF191919)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '알림',
          style: TextStyle(
            color: Color(0xFF191919),
            fontSize: 18,
            fontFamily: 'Pretendard',
            height: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('invitations')
            .where('status', isEqualTo: 'pending')
            .snapshots(includeMetadataChanges: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('새로운 알림이 없습니다.'));
          }

          final invitations = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              final data = invitation.data() as Map<String, dynamic>;
              final groupId = data['groupId'] as String;
              final inviterName = data['inviterName'] as String;
              final role = data['role'] as String;
              final invitedAt = (data['invitedAt'] as Timestamp).toDate();

              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => InviteAcceptAlertDialog(
                      invitationId: invitation.id,
                      groupId: groupId,
                      inviterName: inviterName,
                      role: role,
                      ref: ref,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4), // 아이콘을 위로 올리는 패딩
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: SvgPicture.asset(
                            'assets/icons/ShareMemo.svg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '공유',
                              style: TextStyle(
                                color: Color(0xFF191919),
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '$inviterName님의 그룹 초대가 도착했어요! 눌러서 확인해보세요.',
                              style: const TextStyle(
                                color: Color(0xFF4C4C4C),
                                fontSize: 16,
                                fontFamily: 'Pretendard',
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              DateFormat('M월 d일').format(invitedAt),
                              style: const TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 12,
                                fontFamily: 'Pretendard',
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}