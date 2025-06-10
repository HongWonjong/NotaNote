import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/page_viewmodel.dart';
import 'package:nota_note/pages/memo_page/widgets/editor_toolbar.dart';
import 'package:nota_note/pages/memo_page/widgets/recording_controller_box.dart';
import 'package:nota_note/providers/recording_box_visibility_provider.dart';
import 'package:nota_note/pages/memo_page/widgets/tag_widget.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:nota_note/viewmodels/image_upload_viewmodel.dart';
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
  final quill.QuillController _controller = quill.QuillController.basic();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        ref.read(recordingBoxVisibilityProvider.notifier).state = false;
      }
    });
    _controller.addListener(() {
      ref.read(recordingBoxVisibilityProvider.notifier).state = false;
      if (!mounted) return;
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(Duration(milliseconds: 1500), () {
        if (!mounted) {
          print('Auto-save skipped: Widget not mounted');
          return;
        }
        ref.read(pageViewModelProvider({
          'groupId': widget.groupId,
          'noteId': widget.noteId,
          'pageId': widget.pageId,
        }).notifier).saveToFirestore(_controller).then((_) {
          print('Auto-save completed');
          print('Saved Delta: ${_controller.document.toDelta().toJson()}');
        }).catchError((e) {
          print('Auto-save failed: $e');
        });
      });
    });
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
    final imageUploadViewModel = ref.watch(imageUploadProvider({
      'groupId': widget.groupId,
      'noteId': widget.noteId,
      'pageId': widget.pageId,
      'controller': _controller,
    }).notifier);
    final imageUploadState = ref.watch(imageUploadProvider({
      'groupId': widget.groupId,
      'noteId': widget.noteId,
      'pageId': widget.pageId,
      'controller': _controller,
    }));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (imageUploadState == ImageUploadState.loading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('이미지 업로드 중...'),
              ],
            ),
          ),
        );
      } else if (imageUploadState == ImageUploadState.success) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드 성공')),
        );
        imageUploadViewModel.reset();
      } else if (imageUploadState == ImageUploadState.error) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(imageUploadViewModel.errorMessage ?? '이미지 업로드 실패')),
        );
        imageUploadViewModel.reset();
      }
    });

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
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: KeyboardVisibilityBuilder(
          builder: (context, isKeyboardVisible) => Stack(
            children: [
              Column(
                children: [
                  TagWidget(groupId: widget.groupId, noteId: widget.noteId),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: quill.QuillEditor(
                        controller: _controller,
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        config: quill.QuillEditorConfig(
                          embedBuilders: FlutterQuillEmbeds.editorBuilders(
                            imageEmbedConfig: QuillEditorImageEmbedConfig(
                              imageProviderBuilder: (context, imageUrl) {
                                print('Rendering image: $imageUrl');
                                try {
                                  return imageUploadViewModel.getImageProviderSync(imageUrl);
                                } catch (e) {
                                  print('Failed to load image: $e');
                                  return AssetImage('assets/placeholder.png');
                                }
                              },
                            ),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
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
                  bottom: 80.0 + MediaQuery.of(context).viewInsets.bottom,
                  right: 22.0,
                  child: RecordingControllerBox(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}