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

      List<Page> pages = [];
      List<Comment> comments = [];

      try {
        QuerySnapshot pageDocs = await FirebaseFirestore.instance
            .collection('notegroups')
            .doc(groupId)
            .collection('notes')
            .doc(noteId)
            .collection('pages')
            .get();
        pages = pageDocs.docs.map((pageDoc) {
          return Page.fromFirestore(pageDoc, []);
        }).toList();
      } catch (e) {
      }

      try {
        QuerySnapshot commentDocs = await FirebaseFirestore.instance
            .collection('notegroups')
            .doc(groupId)
            .collection('notes')
            .doc(noteId)
            .collection('comments')
            .get();
        comments = commentDocs.docs.map((commentDoc) {
          return Comment.fromFirestore(commentDoc);
        }).toList();
      } catch (e) {
      }

      if (doc.exists) {
        state = Note.fromFirestore(doc, pages, comments);
      } else {
        state = Note(
          noteId: noteId,
          title: '새 노트',
          ownerId: '',
          isPublic: false,
          tags: [],
          permissions: {},
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
          pages: [],
          comments: [],
        );
        await saveToFirestore();
      }
    } catch (e) {
    }
  }

  Future<void> saveToFirestore() async {
    if (state == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .set(state!.toFirestore(), SetOptions(merge: true));

      for (var page in state!.pages) {
        try {
          await FirebaseFirestore.instance
              .collection('notegroups')
              .doc(groupId)
              .collection('notes')
              .doc(noteId)
              .collection('pages')
              .doc(page.noteId)
              .set(page.toFirestore());
        } catch (e) {
        }
      }

      for (var comment in state!.comments) {
        try {
          await FirebaseFirestore.instance
              .collection('notegroups')
              .doc(groupId)
              .collection('notes')
              .doc(noteId)
              .collection('comments')
              .doc(comment.commentId)
              .set(comment.toFirestore());
        } catch (e) {
        }
      }
    } catch (e) {
    }
  }
}

final noteViewModelProvider = StateNotifierProvider.family<NoteViewModel, Note?, Map<String, String>>(
      (ref, params) => NoteViewModel(
    params['groupId']!,
    params['noteId']!,
  ),
);