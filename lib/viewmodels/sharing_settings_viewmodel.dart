import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nota_note/models/member.dart';

class SharingSettingsViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String groupId;

  SharingSettingsViewModel({required this.groupId});

  // 파이어스토어에서 소유자와 다른 멤버들의 정보를 가지고 와서 멤버 인스턴스로 추가해주자.
  Future<List<Member>> getMembers() async {
    try {
      final groupDoc = await _firestore.collection('notegroups').doc(groupId).get();
      if (!groupDoc.exists) {
        print('Group document not found for groupId: $groupId');
        return [];
      }

      final permissions = List<Map<String, dynamic>>.from(groupDoc.data()?['permissions'] ?? []);
      final creatorId = groupDoc.data()?['creatorId'] as String?;

      List<Member> members = [];

      // Add owner first (based on creatorId)
      if (creatorId != null) {
        final userDoc = await _firestore.collection('users').doc(creatorId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          members.add(Member(
            name: userData['displayName'] ?? 'Unknown',
            hashTag: userData['hashTag'] ?? '@unknown',
            imageUrl: userData['photoUrl'] ?? '',
            role: 'owner',
            isEditable: false,
          ));
        } else {
          print('Owner user not found for creatorId: $creatorId');
        }
      } else {
        print('creatorId is null for groupId: $groupId');
      }

      // Add other members from permissions
      for (var permission in permissions) {
        final userId = permission['userId'] as String;
        final role = permission['role'] as String;

        // Skip if userId is the creator (already added)
        if (userId == creatorId) continue;

        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          members.add(Member(
            name: userData['displayName'] ?? 'Unknown',
            hashTag: userData['hashTag'] ?? '@unknown',
            imageUrl: userData['photoUrl'] ?? '',
            role: role,
            isEditable: role != 'owner',
          ));
        }
      }

      print('Fetched members: $members');
      return members;
    } catch (e) {
      print('Error fetching members: $e');
      return [];
    }
  }

  // Invite new member by hashTag
  Future<bool> inviteMember(String hashTag, String role) async {
    try {
      // Find user by hashTag
      final userQuery = await _firestore
          .collection('users')
          .where('hashTag', isEqualTo: hashTag)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('User not found for hashTag: $hashTag');
        return false; // User not found
      }

      final userId = userQuery.docs.first.id;

      // Update permissions in notegroup
      await _firestore.collection('notegroups').doc(groupId).update({
        'permissions': FieldValue.arrayUnion([
          {
            'userId': userId,
            'role': role, // 'editor' or 'guest'
          }
        ])
      });
      return true;
    } catch (e) {
      print('Error inviting member: $e');
      return false;
    }
  }

  // Update member role
  Future<bool> updateMemberRole(String userId, String newRole) async {
    try {
      // Get current permissions
      final groupDoc = await _firestore.collection('notegroups').doc(groupId).get();
      final permissions = List<Map<String, dynamic>>.from(groupDoc.data()?['permissions'] ?? []);

      // Find and update the specific member's role
      final updatedPermissions = permissions.map((perm) {
        if (perm['userId'] == userId) {
          return {'userId': userId, 'role': newRole};
        }
        return perm;
      }).toList();

      // Update Firestore
      await _firestore.collection('notegroups').doc(groupId).update({
        'permissions': updatedPermissions,
      });
      return true;
    } catch (e) {
      print('Error updating member role: $e');
      return false;
    }
  }

  // Remove member
  Future<bool> removeMember(String userId) async {
    try {
      // Get current permissions
      final groupDoc = await _firestore.collection('notegroups').doc(groupId).get();
      final permissions = List<Map<String, dynamic>>.from(groupDoc.data()?['permissions'] ?? []);

      // Remove the member
      final updatedPermissions = permissions.where((perm) => perm['userId'] != userId).toList();

      // Update Firestore
      await _firestore.collection('notegroups').doc(groupId).update({
        'permissions': updatedPermissions,
      });
      return true;
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }
}