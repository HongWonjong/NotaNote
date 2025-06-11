import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/memo.dart';

final memoViewModelProvider =
ChangeNotifierProvider.family<MemoViewModel, String>((ref, groupId) => MemoViewModel(ref, groupId));

class MemoViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref;
  final String _groupId;

  List<Memo> _memos = [];
  bool _isLoading = false;
  String? _error;

  MemoViewModel(this._ref, this._groupId);

  List<Memo> get memos => _memos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMemos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('notegroups')
          .doc(_groupId)
          .collection('notes')
          .get();

      _memos = querySnapshot.docs
          .map((doc) => Memo.fromFirestore(doc, _groupId))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = "메모를 불러오는 중 오류가 발생했습니다: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMemos(List<String> noteIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

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
      await fetchMemos(); // 메모 목록 갱신
    } catch (e) {
      _error = "메모 삭제 중 오류가 발생했습니다: $e";
      _isLoading = false;
      notifyListeners();
    }
  }
}