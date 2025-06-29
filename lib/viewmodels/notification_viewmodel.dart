import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/auth/user_id_provider.dart';

class NotificationViewModel extends StateNotifier<NotificationViewModelState> {
  NotificationViewModel(this.ref) : super(NotificationViewModelState()) {
    _init();
  }

  final Ref ref;
  StreamSubscription<QuerySnapshot>? _invitationSubscription;

  void _init() {
    ref.listen(userIdProvider, (previous, next) {
      _listenToInvitations(next);
    });
  }

  void _listenToInvitations(String? userId) {
    _invitationSubscription?.cancel();
    if (userId == null) {
      state = state.copyWith(invitationCount: 0, error: '사용자 ID가 없습니다.');
      return;
    }

    _invitationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('invitations')
        .where('status', isEqualTo: 'pending')
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
        state = state.copyWith(
          invitationCount: snapshot.docs.length,
          error: null,
        );
      },
      onError: (error) {
        state = state.copyWith(
          invitationCount: 0,
          error: '초대장 로드 중 오류: $error',
        );
      },
    );
  }

  Future<bool> acceptInvitation(String invitationId, String groupId, String role) async {
    try {
      final userId = ref.read(userIdProvider);
      if (userId == null) {
        state = state.copyWith(error: '사용자 ID가 없습니다.');
        return false;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final invitationRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('invitations')
            .doc(invitationId);

        final groupRef = FirebaseFirestore.instance
            .collection('notegroups')
            .doc(groupId);

        final invitationSnapshot = await transaction.get(invitationRef);
        if (!invitationSnapshot.exists) {
          throw Exception('초대 데이터가 존재하지 않습니다.');
        }

        final newRole = role == 'editor_waiting' ? 'editor' : 'guest';
        final groupSnapshot = await transaction.get(groupRef);
        final permissions = List<Map<String, dynamic>>.from(groupSnapshot.data()?['permissions'] ?? []);
        final updatedPermissions = permissions.map((perm) {
          if (perm['userId'] == userId) {
            return {'userId': userId, 'role': newRole};
          }
          return perm;
        }).toList();

        transaction.update(groupRef, {'permissions': updatedPermissions});
        transaction.delete(invitationRef);
      });

      return true;
    } catch (e) {
      state = state.copyWith(error: '초대 수락 중 오류: $e');
      return false;
    }
  }

  Future<bool> declineInvitation(String invitationId) async {
    try {
      final userId = ref.read(userIdProvider);
      if (userId == null) {
        state = state.copyWith(error: '사용자 ID가 없습니다.');
        return false;
      }

      final invitationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('invitations')
          .doc(invitationId);

      await invitationRef.delete();
      return true;
    } catch (e) {
      state = state.copyWith(error: '초대 거절 중 오류: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _invitationSubscription?.cancel();
    super.dispose();
  }
}

class NotificationViewModelState {
  final int invitationCount;
  final String? error;

  NotificationViewModelState({
    this.invitationCount = 0,
    this.error,
  });

  NotificationViewModelState copyWith({
    int? invitationCount,
    String? error,
  }) {
    return NotificationViewModelState(
      invitationCount: invitationCount ?? this.invitationCount,
      error: error ?? this.error,
    );
  }
}

final notificationViewModelProvider =
StateNotifierProvider<NotificationViewModel, NotificationViewModelState>(
      (ref) => NotificationViewModel(ref),
);