import 'package:flutter_quill/flutter_quill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:nota_note/models/page_model.dart' as page_model;
import 'dart:async';
import 'dart:convert';

class PageViewModel extends StateNotifier<page_model.Page> {
  final String groupId;
  final String noteId;
  final String pageId;
  bool _isLoaded = false;
  StreamSubscription? _subscription;
  bool _isEditing = false;
  DocumentSnapshot? _pendingSnapshot;

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

  void listenToFirestore(QuillController controller, {required bool isEditing}) {
    _isEditing = isEditing;
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('notegroups')
        .doc(groupId)
        .collection('notes')
        .doc(noteId)
        .collection('pages')
        .doc(pageId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        if (_isEditing || snapshot.metadata.hasPendingWrites) {
          _pendingSnapshot = snapshot;
          return;
        }
        await _processSnapshot(controller, snapshot);
      }
    });
  }

  Future<void> _processSnapshot(QuillController controller, DocumentSnapshot snapshot) async {
    final page = page_model.Page.fromFirestore(snapshot);
    final newContentJson = jsonEncode(page.content);
    final currentContentJson = jsonEncode(controller.document.toDelta().toJson());

    if (newContentJson != currentContentJson) {
      try {
        final cursorPosition = controller.selection.baseOffset;
        if (page.content.isNotEmpty) {
          controller.document = Document.fromJson(page.content);
        } else {
          controller.document = Document();
        }
        final newLength = controller.document.length;
        final newCursorPosition = cursorPosition >= 0 && cursorPosition <= newLength
            ? cursorPosition
            : newLength;
        controller.updateSelection(
          TextSelection.collapsed(offset: newCursorPosition),
          ChangeSource.local,
        );
        state = page;
      } catch (e) {
        print('Failed to update document: $e');
      }
    }
    _pendingSnapshot = null;
  }

  void processPendingSnapshot(QuillController controller) async {
    if (_pendingSnapshot != null && !_isEditing) {
      await _processSnapshot(controller, _pendingSnapshot!);
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final pageViewModelProvider = StateNotifierProvider.family<PageViewModel, page_model.Page, Map<String, String>>(
      (ref, params) => PageViewModel(
    params['groupId']!,
    params['noteId']!,
    params['pageId']!,
  ),
);