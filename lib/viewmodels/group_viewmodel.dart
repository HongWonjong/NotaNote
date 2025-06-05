import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/group_model.dart';

final groupViewModelProvider =
    ChangeNotifierProvider((ref) => GroupViewModel());

class GroupViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<GroupModel> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _error = "로그인이 필요합니다";
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 인덱스 오류를 피하기 위해 쿼리 수정
      // 'notegroups' 컬렉션에서 사용자의 그룹 가져오기
      final querySnapshot = await _firestore
          .collection('notegroups')
          .where('userIds', arrayContains: userId)
          .get();

      // 가져온 후 클라이언트에서 정렬
      List<GroupModel> fetchedGroups = querySnapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();

      // 날짜 기준 내림차순 정렬
      fetchedGroups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _groups = fetchedGroups;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = "그룹을 불러오는 중 오류가 발생했습니다: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createGroup(String name) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _error = "로그인이 필요합니다";
        notifyListeners();
        return;
      }

      final newGroup = {
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'userIds': [userId],
        'noteIds': [],
      };

      await _firestore.collection('notegroups').add(newGroup);
      await fetchGroups(); // 그룹 목록 다시 불러오기
    } catch (e) {
      _error = "그룹 생성 중 오류가 발생했습니다: $e";
      notifyListeners();
    }
  }
}
