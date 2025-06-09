import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/group_model.dart';
import 'package:nota_note/pages/login_page/shared_prefs_helper.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';

final groupViewModelProvider =
    ChangeNotifierProvider((ref) => GroupViewModel(ref));

class GroupViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Ref _ref;

  List<GroupModel> _groups = [];
  bool _isLoading = false;
  String? _error;

  GroupViewModel(this._ref);

  List<GroupModel> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Firebase Auth에서 사용자 ID 가져오기 시도
      String? userId = _auth.currentUser?.uid;

      // Firebase Auth에서 ID를 가져오지 못했다면 SharedPreferences에서 시도
      if (userId == null) {
        userId = await getCurrentUserId();
      }

      // 사용자 ID가 없으면 로그인 필요 메시지 표시
      if (userId == null) {
        _error = "로그인이 필요합니다";
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 'notegroups' 컬렉션에서 creatorId가 현재 사용자인 그룹만 가져오기
      final querySnapshot = await _firestore
          .collection('notegroups')
          .where('creatorId', isEqualTo: userId)
          .get();

      // 가져온 후 클라이언트에서 정렬
      List<GroupModel> fetchedGroups = querySnapshot.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .toList();

      // 날짜 기준 내림차순 정렬
      fetchedGroups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _groups = fetchedGroups;

      print('로그인한 사용자($userId)가 생성한 그룹 ${_groups.length}개를 불러왔습니다.');

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
      // Firebase Auth에서 사용자 ID 가져오기 시도
      String? userId = _auth.currentUser?.uid;

      // Firebase Auth에서 ID를 가져오지 못했다면 SharedPreferences에서 시도
      if (userId == null) {
        userId = await getCurrentUserId();
      }

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
        'creatorId': userId,
      };

      await _firestore.collection('notegroups').add(newGroup);
      await fetchGroups(); // 그룹 목록 다시 불러오기
    } catch (e) {
      _error = "그룹 생성 중 오류가 발생했습니다: $e";
      notifyListeners();
    }
  }

  Future<bool> renameGroup(String groupId, String newName) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        userId = await getCurrentUserId();
      }

      if (userId == null) {
        _error = "로그인이 필요합니다";
        notifyListeners();
        return false;
      }

      final docRef = _firestore.collection('notegroups').doc(groupId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        _error = "존재하지 않는 그룹입니다";
        notifyListeners();
        return false;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      final creatorId = data['creatorId'] as String? ?? '';

      if (creatorId != userId) {
        _error = "그룹 이름을 변경할 권한이 없습니다";
        notifyListeners();
        return false;
      }

      await docRef.update({'name': newName});
      await fetchGroups(); // 그룹 목록 다시 불러오기
      return true;
    } catch (e) {
      _error = "그룹 이름 변경 중 오류가 발생했습니다: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        userId = await getCurrentUserId();
      }

      if (userId == null) {
        _error = "로그인이 필요합니다";
        notifyListeners();
        return false;
      }

      final docRef = _firestore.collection('notegroups').doc(groupId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        _error = "존재하지 않는 그룹입니다";
        notifyListeners();
        return false;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      final creatorId = data['creatorId'] as String? ?? '';

      if (creatorId != userId) {
        _error = "그룹을 삭제할 권한이 없습니다";
        notifyListeners();
        return false;
      }

      final notesRef = docRef.collection('notes');
      final notesSnapshot = await notesRef.get();

      for (var noteDoc in notesSnapshot.docs) {
        final noteRef = notesRef.doc(noteDoc.id);

        final pagesRef = noteRef.collection('pages');
        final pagesSnapshot = await pagesRef.get();
        for (var pageDoc in pagesSnapshot.docs) {
          await pagesRef.doc(pageDoc.id).delete();
        }

        final commentsRef = noteRef.collection('comments');
        final commentsSnapshot = await commentsRef.get();
        for (var commentDoc in commentsSnapshot.docs) {
          await commentsRef.doc(commentDoc.id).delete();
        }

        await noteRef.delete();
      }

      await docRef.delete();
      await fetchGroups(); // 그룹 목록 다시 불러오기
      return true;
    } catch (e) {
      _error = "그룹 삭제 중 오류가 발생했습니다: $e";
      notifyListeners();
      return false;
    }
  }

  // 기존 그룹에 creatorId 필드 추가 (마이그레이션용 함수)
  Future<void> updateExistingGroups() async {
    try {
      final querySnapshot = await _firestore
          .collection('notegroups')
          .where('creatorId', isNull: true)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final userIds = List<String>.from(data['userIds'] ?? []);

        // userIds의 첫 번째 사용자를 생성자로 간주
        if (userIds.isNotEmpty) {
          await _firestore
              .collection('notegroups')
              .doc(doc.id)
              .update({'creatorId': userIds[0]});
        }
      }

      print('기존 그룹 업데이트 완료');
    } catch (e) {
      print('기존 그룹 업데이트 오류: $e');
    }
  }
}
