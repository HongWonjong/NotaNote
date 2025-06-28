import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 초대를 수락하여 상태를 'accepted'로 업데이트하고 그룹 권한을 추가
  Future<bool> acceptInvitation(
      String userId, String invitationId, String groupId, String invitationRole) async {
    try {
      // 초대 상태를 accepted로 업데이트
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('invitations')
          .doc(invitationId)
          .update({'status': 'accepted'});

      // 그룹 권한 업데이트
      final groupDoc = await _firestore.collection('notegroups').doc(groupId).get();
      final permissions = List<Map<String, dynamic>>.from(groupDoc.data()?['permissions'] ?? []);
      final updatedPermissions = permissions.map((perm) {
        if (perm['userId'] == userId) {
          return {
            'userId': userId,
            'role': invitationRole == 'editor_waiting' ? 'editor' : 'guest',
          };
        }
        return perm;
      }).toList();

      await _firestore.collection('notegroups').doc(groupId).update({
        'permissions': updatedPermissions,
      });

      print('Invitation accepted for userId: $userId, groupId: $groupId');
      return true;
    } catch (e) {
      print('Error accepting invitation: $e');
      return false;
    }
  }

  /// 초대를 거절하여 상태를 'rejected'로 업데이트하고 그룹 권한에서 제거
  Future<bool> rejectInvitation(String userId, String invitationId, String groupId) async {
    try {
      // 초대 상태를 rejected로 업데이트
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('invitations')
          .doc(invitationId)
          .update({'status': 'rejected'});

      // 그룹 권한에서 사용자 제거
      final groupDoc = await _firestore.collection('notegroups').doc(groupId).get();
      final permissions = List<Map<String, dynamic>>.from(groupDoc.data()?['permissions'] ?? []);
      final updatedPermissions = permissions.where((perm) => perm['userId'] != userId).toList();

      await _firestore.collection('notegroups').doc(groupId).update({
        'permissions': updatedPermissions,
      });

      print('Invitation rejected for userId: $userId, groupId: $groupId');
      return true;
    } catch (e) {
      print('Error rejecting invitation: $e');
      return false;
    }
  }
}