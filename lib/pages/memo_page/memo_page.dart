import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/page_viewmodel.dart';
import 'package:nota_note/pages/memo_page/widgets/editor_toolbar.dart';
import 'package:nota_note/pages/memo_page/widgets/overlay_widgets.dart';
import 'package:nota_note/pages/memo_page/widgets/recording_controller_box.dart';
import 'package:nota_note/providers/recording_box_visibility_provider.dart';
import 'package:nota_note/pages/memo_page/widgets/tag_widget.dart';
import 'dart:async';

class MemoPage extends ConsumerStatefulWidget {
  final String groupId;
  final String noteId;
  final String pageId;

  MemoPage({required this.groupId, required this.noteId, required this.pageId});

  @override
  _MemoPageState createState() => _MemoPageState();
}

class _MemoPageState extends ConsumerState<MemoPage> {
  final QuillController _controller = QuillController.basic();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        ref.read(pageViewModelProvider({
          'groupId': widget.groupId,
          'noteId': widget.noteId,
          'pageId': widget.pageId,
        }).notifier).loadFromFirestore(_controller);
      }
    });
    _controller.addListener(() {
      if (!mounted) return;
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(Duration(milliseconds: 1500), () {
        if (mounted) {
          ref.read(pageViewModelProvider({
            'groupId': widget.groupId,
            'noteId': widget.noteId,
            'pageId': widget.pageId,
          }).notifier).saveToFirestore(_controller).then((_) {
            print('Auto-save completed');
          }).catchError((e) {
            print('Auto-save failed: $e');
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageViewModel = ref.watch(pageViewModelProvider({
      'groupId': widget.groupId,
      'noteId': widget.noteId,
      'pageId': widget.pageId,
    }));
    final isBoxVisible = ref.watch(recordingBoxVisibilityProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            if (mounted) {
              await ref.read(pageViewModelProvider({
                'groupId': widget.groupId,
                'noteId': widget.noteId,
                'pageId': widget.pageId,
              }).notifier).saveToFirestore(_controller);
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share_outlined),
            onPressed: () {
              if (mounted) {
                ref.read(pageViewModelProvider({
                  'groupId': widget.groupId,
                  'noteId': widget.noteId,
                  'pageId': widget.pageId,
                }).notifier).saveToFirestore(_controller);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              print('설정 버튼 클릭');
            },
          ),
        ],
      ),
      body: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) => Stack(
          children: [
            Column(
              children: [
                TagWidget(groupId: widget.groupId, noteId: widget.noteId),
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: QuillEditor(
                          controller: _controller,
                          focusNode: _focusNode,
                          scrollController: _scrollController,
                        ),
                      ),
                      OverlayWidgets(
                        widgets: pageViewModel.widgets,
                        screenWidth: MediaQuery.of(context).size.width,
                        screenHeight: MediaQuery.of(context).size.height,
                      ),
                    ],
                  ),
                ),
                if (isKeyboardVisible)
                  EditorToolbar(
                    controller: _controller,
                    groupId: widget.groupId,
                    noteId: widget.noteId,
                    pageId: widget.pageId,
                  ),
              ],
            ),
            if (isBoxVisible)
              Positioned(
                bottom: 100.0,
                right: 16.0,
                child: RecordingControllerBox(),
              ),
          ],
        ),
      ),
    );
  }
}