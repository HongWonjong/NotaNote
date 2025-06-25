import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/memo.dart';
import 'package:uuid/uuid.dart';

final memoViewModelProvider =
Provider.family<MemoViewModel, String>((ref, groupId) => MemoViewModel(ref, groupId));

class MemoViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref;
  final String _groupId;

  MemoViewModel(this._ref, this._groupId);

  Stream<List<Memo>> get memosStream {
    return _firestore
        .collection('notegroups')
        .doc(_groupId)
        .collection('notes')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Memo.fromFirestore(doc, _groupId))
        .toList());
  }

  Future<String?> addMemo() async {
    try {
      final noteId = const Uuid().v4();
      final now = DateTime.now();
      final docRef = _firestore
          .collection('notegroups')
          .doc(_groupId)
          .collection('notes')
          .doc(noteId);

      await docRef.set({
        'title': '제목 없음',
        'tags': [],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'pageId': '1',
      });

      return noteId;
    } catch (e) {
      throw Exception("메모 추가 중 오류가 발생했습니다: $e");
    }
  }

  Future<void> updateMemoTitleAndContent(String noteId, String title, String content) async {
    try {
      final docRef = _firestore
          .collection('notegroups')
          .doc(_groupId)
          .collection('notes')
          .doc(noteId);
      await docRef.update({
        'title': title,
        'content': content,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception("메모 제목 및 내용 업데이트 중 오류가 발생했습니다: $e");
    }
  }

  Future<void> deleteMemos(List<String> noteIds) async {
    try {
      final batch = _firestore.batch();
      for (var noteId in noteIds) {
        final docRef = _firestore
            .collection('notegroups')
            .doc(_groupId)
            .collection('notes')
            .doc(noteId);
        batch.delete(docRef);
      }
      await batch.commit();
    } catch (e) {
      throw Exception("메모 삭제 중 오류가 발생했습니다: $e");
    }
  }
}