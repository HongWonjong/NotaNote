import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/memo.dart';

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