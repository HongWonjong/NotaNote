import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/page_model.dart';
import 'package:nota_note/models/note_model.dart';
import 'package:nota_note/models/comment_model.dart';

class NoteViewModel extends StateNotifier<Note?> {
  final String groupId;
  final String noteId;

  NoteViewModel(this.groupId, this.noteId) : super(null);

  Future<void> loadFromFirestore() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .get();

      QuerySnapshot pageDocs = await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .collection('pages')
          .get();

      QuerySnapshot commentDocs = await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .collection('comments')
          .get();

      final pages = pageDocs.docs.map((pageDoc) => Page.fromFirestore(pageDoc, [])).toList();
      final comments = commentDocs.docs.map((commentDoc) => Comment.fromFirestore(commentDoc)).toList();

      if (doc.exists) {
        state = Note.fromFirestore(doc, pages, comments);
      }
    } catch (e) {
      print('Firestore 로드 실패: $e');
    }
  }

  Future<void> saveToFirestore() async {
    if (state == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .set(state!.toFirestore());

      for (var page in state!.pages) {
        await FirebaseFirestore.instance
            .collection('notegroups')
            .doc(groupId)
            .collection('notes')
            .doc(noteId)
            .collection('pages')
            .doc(page.noteId)
            .set(page.toFirestore());
      }

      for (var comment in state!.comments) {
        await FirebaseFirestore.instance
            .collection('notegroups')
            .doc(groupId)
            .collection('notes')
            .doc(noteId)
            .collection('comments')
            .doc(comment.commentId)
            .set(comment.toFirestore());
      }
      print('Firestore에 저장 성공');
    } catch (e) {
      print('Firestore 저장 실패: $e');
    }
  }

  void addTag(String tag) {
    if (state != null) {
      final updatedTags = [...state!.tags, tag];
      state = state!.copyWith(tags: updatedTags);
      saveToFirestore();
    }
  }

  void removeTag(String tag) {
    if (state != null) {
      final updatedTags = state!.tags.where((t) => t != tag).toList();
      state = state!.copyWith(tags: updatedTags);
      saveToFirestore();
    }
  }
}

final noteViewModelProvider = StateNotifierProvider.family<NoteViewModel, Note?, Map<String, String>>(
      (ref, params) => NoteViewModel(
    params['groupId']!,
    params['noteId']!,
  ),
);