import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class NoteGroupExampleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createExampleNoteGroup(String userId) async {
    try {
      final groupId = Uuid().v4();
      final noteGroupRef = _firestore.collection('notegroups').doc(groupId);
      await noteGroupRef.set({
        'groupId': groupId,
        'createdAt': Timestamp.fromDate(DateTime(2025, 6, 17, 17, 8, 53)),
        'creatorId': userId,
        'name': '새 그룹',
        'noteIds': [],
        'userIds': [userId],
      });
    } catch (e, st) {
      log('[Example 메모 그룹 생성 실패] $e', stackTrace: st);
    }
  }
}