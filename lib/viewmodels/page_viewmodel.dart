import 'package:flutter_quill/flutter_quill.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/page_model.dart' as page_model;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class PageViewModel extends StateNotifier<page_model.Page> {
  final String groupId;
  final String noteId;
  final String pageId;
  bool _isLoaded = false;
  StreamSubscription? _subscription;
  bool _isEditing = false;
  DocumentSnapshot? _pendingSnapshot;
  String? _lastProcessedContent;

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
          _lastProcessedContent = jsonEncode(page.content);
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
        _lastProcessedContent = jsonEncode([]);
      }
      _isLoaded = true;
    } catch (e) {
      print('Load failed: $e');
    }
  }

  void listenToFirestore(QuillController controller,
      {required bool isEditing}) {
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

  Future<void> _processSnapshot(
      QuillController controller, DocumentSnapshot snapshot) async {
    final page = page_model.Page.fromFirestore(snapshot);
    final newContentJson = jsonEncode(page.content);

    if (_lastProcessedContent == newContentJson) return;

    try {
      final currentContentJson =
      jsonEncode(controller.document.toDelta().toJson());
      final currentLine = _getCurrentLineNumber(controller);

      if (newContentJson != currentContentJson && _isEditing) {
        final mergedContent = _mergeContent(
          controller.document.toDelta().toJson(),
          page.content,
          currentLine,
        );
        if (mergedContent.isNotEmpty) {
          final previousSelection = controller.selection;
          controller.document = Document.fromJson(mergedContent);
          final newLength = controller.document.length;
          final newCursorPosition =
          previousSelection.baseOffset.clamp(0, newLength);
          controller.updateSelection(
            TextSelection.collapsed(offset: newCursorPosition),
            ChangeSource.local,
          );
          state = page.copyWith(content: mergedContent);
          _lastProcessedContent = jsonEncode(mergedContent);
        }
      } else {
        final previousSelection = controller.selection;
        if (page.content.isNotEmpty) {
          controller.document = Document.fromJson(page.content);
        } else {
          controller.document = Document();
        }
        final newLength = controller.document.length;
        final newCursorPosition =
        previousSelection.baseOffset.clamp(0, newLength);
        controller.updateSelection(
          TextSelection.collapsed(offset: newCursorPosition),
          ChangeSource.local,
        );
        state = page;
        _lastProcessedContent = newContentJson;
      }
      _pendingSnapshot = null;
    } catch (e) {
      print('Failed to update document: $e');
    }
  }

  int _getCurrentLineNumber(QuillController controller) {
    final plainText = controller.document.toPlainText();
    final cursorPosition = controller.selection.baseOffset;
    if (cursorPosition < 0 || cursorPosition > plainText.length) return 0;

    final textBeforeCursor = plainText.substring(0, cursorPosition);
    return textBeforeCursor.split('\n').length - 1;
  }

  List<Map<String, dynamic>> _mergeContent(
      List<dynamic> localContent,
      List<Map<String, dynamic>> remoteContent,
      int currentLine,
      ) {
    final localOps = _splitIntoOperationsWithAttributes(localContent);
    final remoteOps = _splitIntoOperationsWithAttributes(remoteContent);
    final localLines = _groupOperationsByLine(localOps);
    final remoteLines = _groupOperationsByLine(remoteOps);

    final mergedLines = <List<Map<String, dynamic>>>[];
    final maxLines = localLines.length > remoteLines.length
        ? localLines.length
        : remoteLines.length;

    for (int i = 0; i < maxLines; i++) {
      // 사용자가 편집 중인 라인은 로컬 데이터를 유지
      if (i == currentLine && localLines.length > i) {
        mergedLines.add(localLines[i]);
      } else {
        // 편집 중이지 않은 라인은 원격 데이터를 우선 사용
        if (remoteLines.length > i) {
          mergedLines.add(remoteLines[i]);
        } else if (localLines.length > i) {
          // 원격 데이터가 없으면 로컬 데이터를 사용
          mergedLines.add(localLines[i]);
        }
      }
    }

    final mergedContent = <Map<String, dynamic>>[];
    for (var line in mergedLines) {
      mergedContent.addAll(line);
    }

    // 병합된 콘텐츠가 비어있지 않은지 확인
    if (mergedContent.isEmpty) {
      mergedContent.add({'insert': '\n'});
    }

    return mergedContent;
  }

  List<Map<String, dynamic>> _splitIntoOperationsWithAttributes(
      List<dynamic> content) {
    final operations = <Map<String, dynamic>>[];
    for (var op in content) {
      if (op['insert'] is String) {
        final text = op['insert'] as String;
        final attributes = op['attributes'] as Map<String, dynamic>?;
        final splitLines = text.split('\n');
        for (int i = 0; i < splitLines.length; i++) {
          final insertText = splitLines[i] + (i < splitLines.length - 1 ? '\n' : '');
          if (insertText.isNotEmpty || i < splitLines.length - 1) {
            operations.add({
              'insert': insertText,
              if (attributes != null) 'attributes': attributes,
            });
          }
        }
      } else {
        operations.add(Map<String, dynamic>.from(op));
      }
    }
    return operations;
  }

  List<List<Map<String, dynamic>>> _groupOperationsByLine(
      List<Map<String, dynamic>> operations) {
    final lines = <List<Map<String, dynamic>>>[];
    var currentLine = <Map<String, dynamic>>[];

    for (var op in operations) {
      if (op['insert'] is String && (op['insert'] as String).endsWith('\n')) {
        currentLine.add(op);
        lines.add(currentLine);
        currentLine = <Map<String, dynamic>>[];
      } else {
        currentLine.add(op);
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines;
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
    _isEditing = true;
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
      _lastProcessedContent = jsonEncode(deltaJson);
      _isEditing = false;
      processPendingSnapshot(controller);
    } catch (e, stackTrace) {
      print('Save failed: $e');
      print('Stack trace: $stackTrace');
      _isEditing = false;
    }
  }

  void setEditing(bool isEditing) {
    _isEditing = isEditing;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final pageViewModelProvider = StateNotifierProvider.family<PageViewModel,
    page_model.Page, Map<String, String>>(
      (ref, params) => PageViewModel(
    params['groupId']!,
    params['noteId']!,
    params['pageId']!,
  ),
);