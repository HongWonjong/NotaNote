import 'package:flutter_quill/flutter_quill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:nota_note/models/page_model.dart' as page_model;

class PageViewModel extends StateNotifier<page_model.Page> {
  final String groupId;
  final String noteId;
  final String pageId;
  bool _isLoaded = false;

  PageViewModel(this.groupId, this.noteId, this.pageId)
      : super(page_model.Page(
    noteId: noteId,
    index: 0,
    title: '새 메모 페이지',
    content: [],
  ));

  Future<void> loadFromFirestore(QuillController controller) async {
    if (_isLoaded) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .collection('pages')
          .doc(pageId)
          .get();

      if (doc.exists) {
        final page = page_model.Page.fromFirestore(doc);
        try {
          if (page.content.isNotEmpty) {
            controller.document = Document.fromJson(page.content);
            final length = controller.document.length;
            controller.updateSelection(
              TextSelection.collapsed(offset: length),
              ChangeSource.local,
            );
          } else {
            controller.document = Document();
          }
        } catch (e) {
          print('Failed to parse Delta JSON: $e');
          controller.document = Document();
        }
        state = page;
      } else {
        final newPage = page_model.Page(
          noteId: noteId,
          index: 0,
          title: '새 메모 페이지',
          content: [],
        );
        await FirebaseFirestore.instance
            .collection('notegroups')
            .doc(groupId)
            .collection('notes')
            .doc(noteId)
            .collection('pages')
            .doc(pageId)
            .set(newPage.toFirestore());
        state = newPage;
        controller.document = Document();
      }
      _isLoaded = true;
    } catch (e) {
      print('Load failed: $e');
    }
  }

  Future<void> saveToFirestore(QuillController controller) async {
    if (!mounted) {
      print('Save skipped: PageViewModel is disposed');
      return;
    }
    final deltaJson = controller.document.toDelta().toJson();
    final page = state.copyWith(content: deltaJson);

    try {
      await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .collection('pages')
          .doc(pageId)
          .set(page.toFirestore());
      state = page;
    } catch (e, stackTrace) {
      print('Save failed: $e');
      print('Stack trace: $stackTrace');
    }
  }
}

final pageViewModelProvider = StateNotifierProvider.family<PageViewModel, page_model.Page, Map<String, String>>(
      (ref, params) => PageViewModel(
    params['groupId']!,
    params['noteId']!,
    params['pageId']!,
  ),
);