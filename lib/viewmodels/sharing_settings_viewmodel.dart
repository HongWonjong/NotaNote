import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nota_note/models/member.dart';

class SharingSettingsViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String groupId;

  SharingSettingsViewModel({required this.groupId});

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

      if (creatorId != null) {
        final userDoc = await _firestore.collection('users').doc(creatorId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          members.add(Member(
            name: userData['displayName'] ?? 'Unknown',
            hashTag: userData['hashTag'] ?? '@unknown',
            imageUrl: userData['photoUrl']?.isNotEmpty == true
                ? userData['photoUrl']
                : 'https://via.placeholder.com/150',
            role: 'owner',
            isEditable: false,
          ));
        } else {
          print('Owner user not found for creatorId: $creatorId');
        }
      } else {
        print('creatorId is null for groupId: $groupId');
      }

      for (var permission in permissions) {
        final userId = permission['userId'] as String;
        final role = permission['role'] as String;

        if (userId == creatorId) continue;

        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          members.add(Member(
            name: userData['displayName'] ?? 'Unknown',
            hashTag: userData['hashTag'] ?? '@unknown',
            imageUrl: userData['photoUrl']?.isNotEmpty == true
                ? userData['photoUrl']
                : 'https://via.placeholder.com/150',
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

  Future<bool> inviteMember(String hashTag, String role, String inviterId) async {
    try {
      final groupDoc = await _firestore.collection('notegroups').doc(groupId).get();
      final permissions = List<Map<String, dynamic>>.from(groupDoc.data()?['permissions'] ?? []);

      final userQueryForExisting = await _firestore
          .collection('users')
          .where('hashTag', isEqualTo: hashTag)
          .limit(1)
          .get();

      if (userQueryForExisting.docs.isNotEmpty) {
        final existingUserId = userQueryForExisting.docs.first.id;
        if (permissions.any((perm) => perm['userId'] == existingUserId)) {
          print('User with hashTag $hashTag is already invited.');
          return false;
        }
      }

      final userQuery = await _firestore
          .collection('users')
          .where('hashTag', isEqualTo: hashTag)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print('User not found for hashTag: $hashTag');
        return false;
      }

      final userId = userQuery.docs.first.id;
      final inviterDoc = await _firestore.collection('users').doc(inviterId).get();
      if (!inviterDoc.exists) {
        print('Inviter not found for inviterId: $inviterId');
        return false;
      }
      final inviterData = inviterDoc.data()!;

      final waitingRole = role == 'editor' ? 'editor_waiting' : 'guest_waiting';

      await _firestore.collection('notegroups').doc(groupId).update({
        'permissions': FieldValue.arrayUnion([
          {
            'userId': userId,
            'role': waitingRole,
          }
        ])
      });

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('invitations')
          .add({
        'groupId': groupId,
        'inviterName': inviterData['displayName'] ?? 'Unknown',
        'inviterHashTag': inviterData['hashTag'] ?? '@unknown',
        'role': waitingRole,
        'invitedAt': Timestamp.now(),
        'status': 'pending',
      });

      print('Invitation sent to $hashTag with role $waitingRole');
      return true;
    } catch (e) {
      print('Error inviting member: $e');
      return false;
    }
  }

  Future<bool> updateMemberRole(String userId, String newRole) async {
    try {
      final groupDoc = await _firestore.collection('notegroups').doc(groupId).get();
      final permissions = List<Map<String, dynamic>>.from(groupDoc.data()?['permissions'] ?? []);

      final updatedPermissions = permissions.map((perm) {
        if (perm['userId'] == userId) {
          return {'userId': userId, 'role': newRole};
        }
        return perm;
      }).toList();

      await _firestore.collection('notegroups').doc(groupId).update({
        'permissions': updatedPermissions,
      });
      return true;
    } catch (e) {
      print('Error updating member role: $e');
      return false;
    }
  }

  Future<bool> cancelInvitation(String userId) async {
    try {
      final groupDoc = await _firestore.collection('notegroups').doc(groupId).get();
      final permissions = List<Map<String, dynamic>>.from(groupDoc.data()?['permissions'] ?? []);

      final updatedPermissions = permissions.where((perm) => perm['userId'] != userId).toList();

      await _firestore.collection('notegroups').doc(groupId).update({
        'permissions': updatedPermissions,
      });

      final invitationQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('invitations')
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in invitationQuery.docs) {
        await doc.reference.delete();
      }

      print('Invitation canceled for userId: $userId');
      return true;
    } catch (e) {
      print('Error canceling invitation: $e');
      return false;
    }
  }

  Future<bool> removeMember(String userId) async {
    try {
      final groupDoc = await _firestore.collection('notegroups').doc(groupId).get();
      final permissions = List<Map<String, dynamic>>.from(groupDoc.data()?['permissions'] ?? []);

      final updatedPermissions = permissions.where((perm) => perm['userId'] != userId).toList();

      await _firestore.collection('notegroups').doc(groupId).update({
        'permissions': updatedPermissions,
      });

      final invitationQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('invitations')
          .where('groupId', isEqualTo: groupId)
          .get();

      for (var doc in invitationQuery.docs) {
        await doc.reference.delete();
      }

      print('Member removed: $userId');
      return true;
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }
}