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
      print('Loading note from Firestore: notegroups/$groupId/notes/$noteId');
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
          print('Loading page: ${pageDoc.id}');
          return Page.fromFirestore(pageDoc, []);
        }).toList();
        print('Loaded ${pages.length} pages');
      } catch (e) {
        print('Failed to load pages: $e');
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
          print('Loading comment: ${commentDoc.id}');
          return Comment.fromFirestore(commentDoc);
        }).toList();
        print('Loaded ${comments.length} comments');
      } catch (e) {
        print('Failed to load comments: $e');
      }

      if (doc.exists) {
        state = Note.fromFirestore(doc, pages, comments);
        print('Loaded note: ${state!.tags}');
      } else {
        print('Note document does not exist, creating default');
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
      print('Firestore load failed: $e');
    }
  }

  Future<void> saveToFirestore() async {
    if (state == null) {
      print('No note to save');
      return;
    }

    try {
      print('Saving note to Firestore: ${state!.tags}');
      await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .set(state!.toFirestore(), SetOptions(merge: true));

      for (var page in state!.pages) {
        try {
          print('Saving page: ${page.noteId}');
          await FirebaseFirestore.instance
              .collection('notegroups')
              .doc(groupId)
              .collection('notes')
              .doc(noteId)
              .collection('pages')
              .doc(page.noteId)
              .set(page.toFirestore());
        } catch (e) {
          print('Failed to save page ${page.noteId}: $e');
        }
      }

      for (var comment in state!.comments) {
        try {
          print('Saving comment: ${comment.commentId}');
          await FirebaseFirestore.instance
              .collection('notegroups')
              .doc(groupId)
              .collection('notes')
              .doc(noteId)
              .collection('comments')
              .doc(comment.commentId)
              .set(comment.toFirestore());
        } catch (e) {
          print('Failed to save comment ${comment.commentId}: $e');
        }
      }
      print('Firestore save successful: ${state!.tags}');
    } catch (e) {
      print('Firestore save failed: $e');
    }
  }
}

final noteViewModelProvider = StateNotifierProvider.family<NoteViewModel, Note?, Map<String, String>>(
      (ref, params) => NoteViewModel(
    params['groupId']!,
    params['noteId']!,
  ),
);