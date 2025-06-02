import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/widget_model.dart' as widget_model;
import 'package:nota_note/viewmodels/page_viewmodel.dart';
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
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isDropdownOpen = false;
  double _defaultFontSize = 16.0;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      ref.read(pageViewModelProvider({
        'groupId': widget.groupId,
        'noteId': widget.noteId,
        'pageId': widget.pageId,
      }).notifier).loadFromFirestore(_controller);
    });
    _controller.addListener(() {
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(Duration(milliseconds: 1500), () {
        ref.read(pageViewModelProvider({
          'groupId': widget.groupId,
          'noteId': widget.noteId,
          'pageId': widget.pageId,
        }).notifier).saveToFirestore(_controller).then((_) {
          print('Auto-save completed');
        }).catchError((e) {
          print('Auto-save failed: $e');
        });
      });
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleDropdown(BuildContext context) {
    if (_isDropdownOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isDropdownOpen = false;
    } else {
      _overlayEntry = _createOverlayEntry(context);
      Overlay.of(context).insert(_overlayEntry!);
      _isDropdownOpen = true;
    }
    setState(() {});
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 100.0,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, -5 * 48.0),
          child: Material(
            elevation: 4.0,
            child: Container(
              height: 5 * 48.0,
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [12.0, 14.0, 16.0, 18.0, 20.0].map((size) {
                  return GestureDetector(
                    onTap: () {
                      final selection = _controller.selection;
                      if (selection.isValid) {
                        _controller.formatText(
                          selection.start,
                          selection.end - selection.start,
                          Attribute.fromKeyValue('size', size.toInt()),
                        );
                        if (selection.isCollapsed) {
                          setState(() {
                            _defaultFontSize = size;
                          });
                        }
                      } else {
                        setState(() {
                          _defaultFontSize = size;
                        });
                      }
                      _toggleDropdown(context);
                    },
                    child: Container(
                      height: 48.0,
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Center(child: Text('$size')),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getCurrentFontSize() {
    final selection = _controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final style = _controller.getSelectionStyle();
      if (style.attributes.containsKey('size')) {
        return (style.attributes['size']!.value as int).toDouble();
      }
    }
    return _defaultFontSize;
  }

  @override
  Widget build(BuildContext context) {
    final pageViewModel = ref.watch(pageViewModelProvider({
      'groupId': widget.groupId,
      'noteId': widget.noteId,
      'pageId': widget.pageId,
    }));
    final overlayWidgets = pageViewModel.widgets;
    final currentFontSize = _getCurrentFontSize();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.ios_share_outlined),
            onPressed: () {
              ref.read(pageViewModelProvider({
                'groupId': widget.groupId,
                'noteId': widget.noteId,
                'pageId': widget.pageId,
              }).notifier).saveToFirestore(_controller);
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
        builder: (context, isKeyboardVisible) => Column(
          children: [
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
                  for (var widget in overlayWidgets)
                    Positioned(
                      left: widget.position['xFactor']! * screenWidth,
                      top: widget.position['yFactor']! * screenHeight,
                      child: Container(
                        width: widget.size['widthFactor']! * screenWidth,
                        height: widget.size['heightFactor']! * screenHeight,
                        child: widget.type == 'image'
                            ? Image.network(widget.content['imageUrl'] ?? '', fit: BoxFit.cover)
                            : Text(widget.content['url'] ?? ''),
                      ),
                    ),
                ],
              ),
            ),
            if (isKeyboardVisible)
              Container(
                color: Colors.grey[200],
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.camera_alt),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.mic),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Row(
                          children: [
                            Icon(Icons.smart_toy),
                            SizedBox(width: 4.0),
                            Text('AI'),
                          ],
                        ),
                        onPressed: () {
                          print('AI 버튼 클릭');
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.format_bold),
                        onPressed: () {
                          _controller.formatSelection(Attribute.bold);
                        },
                      ),
                      CompositedTransformTarget(
                        link: _layerLink,
                        child: GestureDetector(
                          onTap: () => _toggleDropdown(context),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text('$currentFontSize'),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Row(
                        children: List.generate(5, (index) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.0),
                          child: Container(
                            width: 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == 2 ? Colors.black : Colors.grey,
                            ),
                          ),
                        )),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}