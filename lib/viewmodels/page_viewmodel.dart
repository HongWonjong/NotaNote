import 'package:flutter_quill/flutter_quill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/page_model.dart' as page_model;
import 'package:nota_note/models/widget_model.dart' as widget_model;
import 'package:flutter/services.dart';

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
    widgets: [],
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

      QuerySnapshot widgetDocs = await FirebaseFirestore.instance
          .collection('notegroups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .collection('pages')
          .doc(pageId)
          .collection('widgets')
          .get();

      final widgets = widgetDocs.docs.map((doc) {
        return widget_model.Widget.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      if (doc.exists) {
        final page = page_model.Page.fromFirestore(doc, widgets);
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
          controller.document = Document();
        }
        state = page;
      } else {
        final newPage = page_model.Page(
          noteId: noteId,
          index: 0,
          title: '새 메모 페이지',
          content: [],
          widgets: [],
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
    }
  }

  Future<void> saveToFirestore(QuillController controller) async {
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

      for (var widget in page.widgets) {
        await FirebaseFirestore.instance
            .collection('notegroups')
            .doc(groupId)
            .collection('notes')
            .doc(noteId)
            .collection('pages')
            .doc(pageId)
            .collection('widgets')
            .doc(widget.widgetId)
            .set(widget.toFirestore());
      }
      state = page;
    } catch (e) {
    }
  }
}

final pageViewModelProvider = StateNotifierProvider.family.autoDispose<PageViewModel, page_model.Page, Map<String, String>>(
      (ref, params) => PageViewModel(
    params['groupId']!,
    params['noteId']!,
    params['pageId']!,
  ),
);