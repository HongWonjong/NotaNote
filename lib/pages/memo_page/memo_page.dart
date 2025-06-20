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
import 'package:nota_note/viewmodels/memo_viewmodel.dart';
import 'package:nota_note/pages/memo_page/widgets/popup_menu_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  String? _lastDeltaJson;
  bool _isPopupVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !ref.read(recordingBoxVisibilityProvider)) {
        ref.read(recordingBoxVisibilityProvider.notifier).state = false;
      }
    });
    _controller.addListener(() {
      ref.read(recordingBoxVisibilityProvider.notifier).state = false;
      if (!mounted) return;
      final currentDeltaJson = _controller.document.toDelta().toJson().toString();
      if (currentDeltaJson == _lastDeltaJson) return;
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(Duration(milliseconds: 1500), () {
        if (!mounted) return;
        _saveContentAndTitle();
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

  Future<void> _saveContentAndTitle() async {
    try {
      final delta = _controller.document.toDelta();
      final deltaJson = delta.toJson();
      if (deltaJson.isEmpty || (deltaJson.length == 1 && deltaJson[0]['insert'] == '\n')) {
        return;
      }
      await ref.read(pageViewModelProvider({
        'groupId': widget.groupId,
        'noteId': widget.noteId,
        'pageId': widget.pageId,
      }).notifier).saveToFirestore(_controller);
      _lastDeltaJson = deltaJson.toString();

      String firstText = '제목 없음';
      for (var op in deltaJson) {
        if (op['insert'] is String) {
          firstText = (op['insert'] as String).trim().split('\n').first;
          if (firstText.isEmpty) firstText = '제목 없음';
          if (firstText.length > 50) firstText = firstText.substring(0, 50);
          break;
        }
      }
      await ref.read(memoViewModelProvider(widget.groupId)).updateMemoTitle(widget.noteId, firstText);
    } catch (e) {
      debugPrint('Save failed: $e');
    }
  }

  void _togglePopupMenu() {
    setState(() {
      _isPopupVisible = !_isPopupVisible;
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
    final screenWidth = MediaQuery.of(context).size.width;
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
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;

    if (imageUploadState == ImageUploadState.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      });
    } else if (imageUploadState == ImageUploadState.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드 성공')),
        );
        imageUploadViewModel.reset();
      });
    } else if (imageUploadState == ImageUploadState.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(imageUploadViewModel.errorMessage ?? '이미지 업로드 실패')),
        );
        imageUploadViewModel.reset();
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/Arrow.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () async {
            if (mounted) {
              await _saveContentAndTitle();
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/Share.svg',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              if (mounted) {
                _saveContentAndTitle();
              }
            },
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/DotCircle.svg',
              width: 24,
              height: 24,
            ),
            onPressed: _togglePopupMenu,
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
            child: KeyboardVisibilityBuilder(
              builder: (context, isKeyboardVisible) => Column(
                children: [
                  SizedBox(height: 60),
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
                                try {
                                  return imageUploadViewModel.getImageProviderSync(imageUrl);
                                } catch (e) {
                                  debugPrint('Failed to load image: $e');
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
                ],
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: TagWidget(groupId: widget.groupId, noteId: widget.noteId),
          ),
          KeyboardVisibilityBuilder(
            builder: (context, isKeyboardVisible) => Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 0,
              right: 0,
              child: Container(
                width: screenWidth,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isBoxVisible)
                      RecordingControllerBox(
                        controller: _controller,
                        focusNode: _focusNode,
                      ),
                    SizedBox(height: 10,),
                    if (isKeyboardVisible)
                      EditorToolbar(
                        controller: _controller,
                        groupId: widget.groupId,
                        noteId: widget.noteId,
                        pageId: widget.pageId,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_isPopupVisible)
            GestureDetector(
              onTap: _togglePopupMenu,
              child: Container(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    Positioned(
                      top: appBarHeight / 8,
                      right: 10,
                      child: PopupMenuWidget(onClose: _togglePopupMenu),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}