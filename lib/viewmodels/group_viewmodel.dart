import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/group_model.dart';
import 'package:nota_note/pages/login_page/shared_prefs_helper.dart';
import 'package:nota_note/viewmodels/auth/auth_common.dart';
import 'package:nota_note/models/role.dart';
import 'package:nota_note/models/shared_group_with_role.dart';

final groupViewModelProvider =
ChangeNotifierProvider((ref) => GroupViewModel(ref));

class GroupViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Ref _ref;

  List<GroupModel> _ownedGroups = [];
  List<SharedGroupWithRole> _sharedGroupsWithRole = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<QuerySnapshot>? _ownedGroupSubscription;
  StreamSubscription<QuerySnapshot>? _sharedGroupSubscription;
  Map<String, StreamSubscription<QuerySnapshot>> _notesSubscriptions = {};
  List<GroupModel> _filteredOwnedGroups = [];
  List<SharedGroupWithRole> _filteredSharedGroupsWithRole = [];
  String _searchQuery = '';

  GroupViewModel(this._ref) {
    _init();
  }

  List<GroupModel> get ownedGroups => _ownedGroups;
  List<SharedGroupWithRole> get sharedGroupsWithRole => _sharedGroupsWithRole;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<GroupModel> get filteredOwnedGroups =>
      _searchQuery.isEmpty ? _ownedGroups : _filteredOwnedGroups;
  List<SharedGroupWithRole> get filteredSharedGroupsWithRole =>
      _searchQuery.isEmpty ? _sharedGroupsWithRole : _filteredSharedGroupsWithRole;
  String get searchQuery => _searchQuery;

  void _init() {
    fetchGroupsWithNoteCounts();
  }

  Future<void> fetchGroupsWithNoteCounts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? userId = _auth.currentUser?.uid;

      if (userId == null) {
        userId = await getCurrentUserId();
      }

      if (userId == null) {
        _error = "로그인이 필요합니다";
        _isLoading = false;
        notifyListeners();
        return;
      }

      _listenToOwnedGroups(userId);
      _listenToSharedGroups(userId);
    } catch (e) {
      _error = "그룹을 불러오는 중 오류가 발생했습니다: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToOwnedGroups(String userId) {
    _ownedGroupSubscription?.cancel();
    _notesSubscriptions.values.forEach((sub) => sub.cancel());
    _notesSubscriptions.clear();

    _ownedGroupSubscription = _firestore
        .collection('notegroups')
        .where('creatorId', isEqualTo: userId)
        .snapshots()
        .listen((querySnapshot) async {
      List<GroupModel> fetchedGroups = [];

      for (var doc in querySnapshot.docs) {
        final groupId = doc.id;
        if (!_notesSubscriptions.containsKey(groupId)) {
          _listenToNotes(groupId, doc, isOwned: true);
        }
      }

      for (var doc in querySnapshot.docs) {
        final noteCount = _ownedGroups
            .firstWhere((group) => group.id == doc.id,
            orElse: () => GroupModel.fromFirestore(doc, noteCount: 0))
            .noteCount;
        fetchedGroups.add(GroupModel.fromFirestore(doc, noteCount: noteCount));
      }

      fetchedGroups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _ownedGroups = fetchedGroups;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = "소유자 그룹을 불러오는 중 오류가 발생했습니다: $e";
      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenToSharedGroups(String userId) {
    _sharedGroupSubscription?.cancel();

    _sharedGroupSubscription = _firestore
        .collection('notegroups')
        .where('permissions', arrayContainsAny: [
      {'userId': userId, 'role': 'editor'},
      {'userId': userId, 'role': 'guest'},
    ])
        .snapshots()
        .listen((querySnapshot) async {
      List<SharedGroupWithRole> fetchedGroupsWithRole = [];

      for (var doc in querySnapshot.docs) {
        final groupId = doc.id;
        if (!_notesSubscriptions.containsKey(groupId)) {
          _listenToNotes(groupId, doc, isOwned: false);
        }
      }

      for (var doc in querySnapshot.docs) {
        final group = GroupModel.fromFirestore(doc, noteCount: 0);
        final permissions = List<Map<String, dynamic>>.from(doc['permissions'] ?? []);
        final userPermission = permissions.firstWhere(
              (perm) => perm['userId'] == userId,
          orElse: () => {'role': Role.guest.value},
        );
        final role = userPermission['role'] ?? Role.guest.value;
        final noteCount = _sharedGroupsWithRole
            .firstWhere(
                (g) => g.group.id == doc.id,
            orElse: () => SharedGroupWithRole(group: group, role: role))
            .group
            .noteCount;
        fetchedGroupsWithRole.add(SharedGroupWithRole(
          group: GroupModel.fromFirestore(doc, noteCount: noteCount),
          role: role,
        ));
      }

      fetchedGroupsWithRole.sort((a, b) => b.group.createdAt.compareTo(a.group.createdAt));

      _sharedGroupsWithRole = fetchedGroupsWithRole;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = "공유된 그룹을 불러오는 중 오류가 발생했습니다: $e";
      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenToNotes(String groupId, DocumentSnapshot groupDoc, {required bool isOwned}) {
    final notesRef =
    _firestore.collection('notegroups').doc(groupId).collection('notes');

    _notesSubscriptions[groupId] = notesRef.snapshots().listen((notesSnapshot) {
      final noteCount = notesSnapshot.docs.length;
      if (isOwned) {
        final updatedGroups = _ownedGroups.map((group) {
          if (group.id == groupId) {
            return GroupModel.fromFirestore(groupDoc, noteCount: noteCount);
          }
          return group;
        }).toList();

        updatedGroups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _ownedGroups = updatedGroups;
      } else {
        final updatedGroups = _sharedGroupsWithRole.map((sharedGroup) {
          if (sharedGroup.group.id == groupId) {
            return SharedGroupWithRole(
              group: GroupModel.fromFirestore(groupDoc, noteCount: noteCount),
              role: sharedGroup.role,
            );
          }
          return sharedGroup;
        }).toList();

        updatedGroups.sort((a, b) => b.group.createdAt.compareTo(a.group.createdAt));
        _sharedGroupsWithRole = updatedGroups;
      }
      notifyListeners();
    }, onError: (e) {
      _error = "노트 수를 불러오는 중 오류가 발생했습니다: $e";
      notifyListeners();
    });
  }

  Future<void> createGroup(String name) async {
    try {
      String? userId = _auth.currentUser?.uid;

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
        'permissions': [],
      };

      await _firestore.collection('notegroups').add(newGroup);
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

      bool result = await _firestore.runTransaction<bool>((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          throw Exception("존재하지 않는 그룹입니다");
        }

        final data = docSnapshot.data() as Map<String, dynamic>;
        final creatorId = data['creatorId'] as String? ?? '';

        if (creatorId != userId) {
          throw Exception("그룹 이름을 변경할 권한이 없습니다");
        }

        transaction.update(docRef, {'name': newName});
        return true;
      });

      return result;
    } catch (e) {
      if (e is Exception) {
        _error = e.toString().replaceAll('Exception: ', '');
      } else {
        _error = "그룹 이름 변경 중 오류가 발생했습니다: $e";
      }
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

      _notesSubscriptions.remove(groupId)?.cancel();
      return true;
    } catch (e) {
      _error = "그룹 삭제 중 오류가 발생했습니다: $e";
      notifyListeners();
      return false;
    }
  }

  Future<void> updateExistingGroups() async {
    try {
      final querySnapshot = await _firestore
          .collection('notegroups')
          .where('creatorId', isNull: true)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final userIds = List<String>.from(data['userIds'] ?? []);

        if (userIds.isNotEmpty) {
          await _firestore
              .collection('notegroups')
              .doc(doc.id)
              .update({'creatorId': userIds[0]});
        }
      }
    } catch (e) {}
  }

  void searchGroups(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredOwnedGroups = [];
      _filteredSharedGroupsWithRole = [];
    } else {
      _filteredOwnedGroups = _ownedGroups
          .where(
              (group) => group.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _filteredSharedGroupsWithRole = _sharedGroupsWithRole
          .where((sharedGroup) =>
          sharedGroup.group.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ownedGroupSubscription?.cancel();
    _sharedGroupSubscription?.cancel();
    _notesSubscriptions.values.forEach((sub) => sub.cancel());
    _notesSubscriptions.clear();
    super.dispose();
  }
}