import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/note_model.dart';
import 'package:nota_note/models/page_model.dart';
import 'package:nota_note/models/comment_model.dart';

final notesListViewModelProvider =
    ChangeNotifierProvider.family<NotesListViewModel, String>(
  (ref, groupId) => NotesListViewModel(groupId),
);

class NotesListViewModel extends ChangeNotifier {
  final String groupId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;

  NotesListViewModel(this.groupId);

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final notesSnapshot = await _firestore
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .orderBy('updatedAt', descending: true)
          .get();

      List<Note> fetchedNotes = [];

      for (var noteDoc in notesSnapshot.docs) {
        final pagesSnapshot = await _firestore
            .collection('notegroups')
            .doc(groupId)
            .collection('notes')
            .doc(noteDoc.id)
            .collection('pages')
            .get();

        final pages = pagesSnapshot.docs
            .map((pageDoc) => Page.fromFirestore(pageDoc))
            .toList();

        final commentsSnapshot = await _firestore
            .collection('notegroups')
            .doc(groupId)
            .collection('notes')
            .doc(noteDoc.id)
            .collection('comments')
            .get();

        final comments = commentsSnapshot.docs
            .map((commentDoc) => Comment.fromFirestore(commentDoc))
            .toList();

        fetchedNotes.add(Note.fromFirestore(noteDoc, pages, comments));
      }

      _notes = fetchedNotes;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = "노트 목록을 불러오는 중 오류가 발생했습니다: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createNote(String title) async {
    try {
      final noteData = {
        'title': title,
        'ownerId': '',
        'isPublic': false,
        'tags': [],
        'permissions': {},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      DocumentReference noteRef = await _firestore
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .add(noteData);

      await noteRef.collection('pages').add({
        'title': '페이지 1',
        'content': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'widgets': [],
      });

      await fetchNotes();
    } catch (e) {
      _error = "노트 생성 중 오류가 발생했습니다: $e";
      notifyListeners();
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _firestore
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .delete();

      await fetchNotes();
    } catch (e) {
      _error = "노트 삭제 중 오류가 발생했습니다: $e";
      notifyListeners();
    }
  }
}
