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
  bool _isTagVisible = true;

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
      _adjustScrollForCursor();
    });
    _scrollController.addListener(() {
      setState(() {
        _isTagVisible = _scrollController.offset <= 0;
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
      String? secondText;
      int lineCount = 0;

      for (var op in deltaJson) {
        if (op['insert'] is String) {
          final lines = (op['insert'] as String).trim().split('\n');
          for (var line in lines) {
            if (line.isNotEmpty) {
              if (lineCount == 0) {
                firstText = line;
                if (firstText.length > 50) firstText = firstText.substring(0, 50);
              } else if (lineCount >= 1 && secondText == null) {
                if (line.trim().isNotEmpty) {
                  secondText = line;
                  if (secondText.length > 100) secondText = secondText.substring(0, 100);
                }
              }
              lineCount++;
            }
          }
          if (lineCount > 0 && secondText != null) break;
        }
      }

      await ref.read(memoViewModelProvider(widget.groupId)).updateMemoTitleAndContent(widget.noteId, firstText, secondText ?? '');
    } catch (e) {
      debugPrint('Save failed: $e');
    }
  }

  void _togglePopupMenu() {
    setState(() {
      _isPopupVisible = !_isPopupVisible;
    });
  }

  void _adjustScrollForCursor() {
    if (!_focusNode.hasFocus) return;
    final cursorPosition = _controller.selection.baseOffset;
    if (cursorPosition < 0) return;

    final editorKey = GlobalKey();
    final renderObject = (editorKey.currentContext?.findRenderObject() as RenderBox?);
    if (renderObject == null) return;

    final cursorHeight = 20.0;
    final toolbarHeight = 60.0;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final offset = _scrollController.offset;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final newOffset = offset + cursorHeight + toolbarHeight + keyboardHeight;
        if (newOffset <= maxScroll) {
          _scrollController.animateTo(
            newOffset,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
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
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 20),
          child: IconButton(
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
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/DotCircle.svg',
                width: 24,
                height: 24,
              ),
              onPressed: _togglePopupMenu,
            ),
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
                  AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    height: _isTagVisible ? 80 : 0,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isKeyboardVisible ? 55.0 : 0.0),
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
          AnimatedPositioned(
            duration: Duration(milliseconds: 150),
            top: _isTagVisible ? 20 : -100,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 150),
              opacity: _isTagVisible ? 1.0 : 0.0,
              child: TagWidget(groupId: widget.groupId, noteId: widget.noteId),
            ),
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
                    SizedBox(height: 10),
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
                      child: PopupMenuWidget(
                        onClose: _togglePopupMenu,
                        groupId: widget.groupId,
                        noteId: widget.noteId,
                      ),
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