import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:nota_note/providers/recording_box_visibility_provider.dart';
import 'package:nota_note/providers/toolbar_scroll_offset_provider.dart';
import 'package:nota_note/viewmodels/page_viewmodel.dart';
import 'camera_selection_dialog.dart';
import 'color_picker_widget.dart';
import 'highlight_picker_widget.dart';

class EditorToolbar extends ConsumerStatefulWidget {
  final QuillController controller;
  final String groupId;
  final String noteId;
  final String pageId;
  final String role;

  EditorToolbar({
    required this.controller,
    required this.groupId,
    required this.noteId,
    required this.pageId,
    required this.role,
  });

  @override
  _EditorToolbarState createState() => _EditorToolbarState();
}

class _EditorToolbarState extends ConsumerState<EditorToolbar> {
  OverlayEntry? _overlayEntry;
  OverlayEntry? _colorOverlayEntry;
  OverlayEntry? _highlightOverlayEntry;
  final LayerLink _layerLink = LayerLink();
  final LayerLink _colorLayerLink = LayerLink();
  final LayerLink _highlightLayerLink = LayerLink();
  bool _isDropdownOpen = false;
  bool _isColorPickerOpen = false;
  bool _isHighlightPickerOpen = false;
  final ScrollController _scrollController = ScrollController();
  static const String _zeroWidthSpace = '\u200B';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (mounted) setState(() {});
    });

    _scrollController.addListener(() {
      ref.read(toolbarScrollOffsetProvider.notifier).state =
          _scrollController.offset;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedOffset = ref.read(toolbarScrollOffsetProvider);
      if (_scrollController.hasClients && savedOffset > 0) {
        _scrollController.jumpTo(savedOffset);
      } else {
        Future.delayed(Duration(milliseconds: 100), () {
          if (_scrollController.hasClients && mounted) {
            _scrollController.jumpTo(savedOffset);
          }
        });
      }
    });
  }

  void applyFormatsWithPlaceholder(Map<String, Attribute> attributes) async {
    final viewModel = ref.read(pageViewModelProvider({
      'groupId': widget.groupId,
      'noteId': widget.noteId,
      'pageId': widget.pageId,
    }).notifier);

    viewModel.setEditing(true); // 포맷팅 시작 시 편집 상태로 설정

    final selection = widget.controller.selection;
    if (!selection.isValid) {
      viewModel.setEditing(false);
      return;
    }

    final document = widget.controller.document;

    if (selection.isCollapsed) {
      final index = selection.start;
      document.insert(index, _zeroWidthSpace);
      attributes.forEach((key, attribute) {
        document.format(index, 1, attribute);
      });
      document.insert(index + 1, _zeroWidthSpace);
      attributes.forEach((key, attribute) {
        document.format(index + 1, 1, attribute);
      });
      widget.controller.updateSelection(
        TextSelection.collapsed(offset: index + 2),
        ChangeSource.local,
      );
    } else {
      final start = selection.start;
      final length = selection.end - selection.start;
      attributes.forEach((key, attribute) {
        widget.controller.formatText(start, length, attribute);
      });
      widget.controller.updateSelection(
        TextSelection(baseOffset: start, extentOffset: selection.end),
        ChangeSource.local,
      );
    }

    // Firestore에 저장
    await viewModel.saveToFirestore(widget.controller);

    viewModel.setEditing(false); // 저장 완료 후 편집 상태 해제

    if (mounted) setState(() {});
  }

  void _toggleDropdown(BuildContext context) {
    if (_isDropdownOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isDropdownOpen = false;
    } else {
      ref.read(recordingBoxVisibilityProvider.notifier).state = false;
      _overlayEntry = _createOverlayEntry(context);
      Overlay.of(context).insert(_overlayEntry!);
      _isDropdownOpen = true;
    }
    if (mounted) setState(() {});
  }

  void _toggleColorPicker(BuildContext context) {
    if (_isColorPickerOpen) {
      _colorOverlayEntry?.remove();
      _colorOverlayEntry = null;
      _isColorPickerOpen = false;
    } else {
      ref.read(recordingBoxVisibilityProvider.notifier).state = false;
      _colorOverlayEntry = _createColorOverlayEntry(context);
      Overlay.of(context).insert(_colorOverlayEntry!);
      _isColorPickerOpen = true;
    }
    if (mounted) setState(() {});
  }

  void _toggleHighlightPicker(BuildContext context) {
    if (_isHighlightPickerOpen) {
      _highlightOverlayEntry?.remove();
      _highlightOverlayEntry = null;
      _isHighlightPickerOpen = false;
    } else {
      ref.read(recordingBoxVisibilityProvider.notifier).state = false;
      _highlightOverlayEntry = _createHighlightOverlayEntry(context);
      Overlay.of(context).insert(_highlightOverlayEntry!);
      _isHighlightPickerOpen = true;
    }
    if (mounted) setState(() {});
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 120.0,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, -220),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  {'label': '제목', 'size': 32.0},
                  {'label': '부제목', 'size': 24.0},
                  {'label': '본문', 'size': 16.0},
                  {'label': '작은 텍스트', 'size': 12.0},
                ].map((option) {
                  return _buildFontSizeOption(context,
                      option['label'] as String, option['size'] as double);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  OverlayEntry _createColorOverlayEntry(BuildContext context) {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 274,
        child: CompositedTransformFollower(
          link: _colorLayerLink,
          showWhenUnlinked: false,
          offset: Offset(-100, -65),
          child: ColorPickerWidget(
            controller: widget.controller,
            onClose: () => _toggleColorPicker(context),
            onColorSelected: (color) {
              final attribute = Attribute.fromKeyValue(
                'color',
                '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
              );
              if (attribute != null) {
                applyFormatsWithPlaceholder({'color': attribute});
              }
            },
          ),
        ),
      ),
    );
  }

  OverlayEntry _createHighlightOverlayEntry(BuildContext context) {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 274,
        child: CompositedTransformFollower(
          link: _highlightLayerLink,
          showWhenUnlinked: false,
          offset: Offset(-100, -65),
          child: HighlightPickerWidget(
            controller: widget.controller,
            onClose: () => _toggleHighlightPicker(context),
            onHighlightSelected: (color) {
              final attribute = color == null
                  ? Attribute.clone(Attribute.background, null)
                  : Attribute.fromKeyValue(
                'background',
                '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
              );
              if (attribute != null) {
                applyFormatsWithPlaceholder({'background': attribute});
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFontSizeOption(BuildContext context, String label, double size) {
    bool isPressed = false;
    final style = widget.controller.getSelectionStyle();
    final currentSize = style.attributes['size']?.value?.toDouble();
    bool isSelected = currentSize == size;

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapCancel: () => setState(() => isPressed = false),
          onTap: () async {
            setState(() => isPressed = true);
            final attribute = Attribute.fromKeyValue('size', size.toInt());
            if (attribute != null) {
              applyFormatsWithPlaceholder({'size': attribute}); // await 제거
            }
            await Future.delayed(Duration(milliseconds: 100));
            setState(() => isPressed = false);
            _toggleDropdown(context);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 100),
            height: size + 30.0,
            width: 120.0,
            color: isPressed
                ? Colors.grey[200]
                : isSelected
                ? Colors.grey[300]
                : Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(fontSize: size, color: Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    if (duration.inMinutes >= 60) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  bool _isFormatActive(Attribute attribute) {
    final style = widget.controller.getSelectionStyle();
    return style.attributes.containsKey(attribute.key) &&
        style.attributes[attribute.key]!.value != null;
  }

  bool _isListActive(String listType) {
    final style = widget.controller.getSelectionStyle();
    return style.attributes.containsKey(Attribute.list.key) &&
        style.attributes[Attribute.list.key]!.value == listType;
  }

  bool _isAlignActive(String alignType) {
    final style = widget.controller.getSelectionStyle();
    return style.attributes.containsKey(Attribute.align.key) &&
        style.attributes[Attribute.align.key]!.value == alignType;
  }

  void _toggleFormat(Attribute attribute) {
    final isActive = _isFormatActive(attribute);
    final newAttribute =
    isActive ? Attribute.clone(attribute, null) : attribute;
    if (newAttribute != null) {
      applyFormatsWithPlaceholder({attribute.key: newAttribute});
    }
  }

  void _increaseIndent() {
    final selection = widget.controller.selection;
    if (selection.isValid) {
      final style = widget.controller.getSelectionStyle();
      final currentIndent = style.attributes['indent']?.value as int? ?? 0;
      final attribute = Attribute.fromKeyValue('indent', currentIndent + 1);
      if (attribute != null) {
        applyFormatsWithPlaceholder({'indent': attribute});
      }
    }
  }

  void _decreaseIndent() {
    final selection = widget.controller.selection;
    if (selection.isValid) {
      final style = widget.controller.getSelectionStyle();
      final currentIndent = style.attributes['indent']?.value as int? ?? 0;
      final attribute = currentIndent > 0
          ? Attribute.fromKeyValue('indent', currentIndent - 1)
          : Attribute.clone(Attribute.indent, null);
      if (attribute != null) {
        applyFormatsWithPlaceholder({'indent': attribute});
      }
    }
  }

  void _toggleList(String listType) {
    final isActive = _isListActive(listType);
    final attribute = isActive
        ? Attribute.clone(Attribute.list, null)
        : Attribute.fromKeyValue('list', listType);
    if (attribute != null) {
      applyFormatsWithPlaceholder({'list': attribute});
    }
  }

  void _toggleAlign(String alignType) {
    final isActive = _isAlignActive(alignType);
    final attribute = isActive
        ? Attribute.clone(Attribute.align, null)
        : Attribute.fromKeyValue('align', alignType);
    if (attribute != null) {
      applyFormatsWithPlaceholder({'align': attribute});
    }
  }

  void _insertCodeBlock() {
    final selection = widget.controller.selection;
    if (selection.isValid && selection.start != selection.end) {
      widget.controller.formatText(
        selection.start,
        selection.end - selection.start,
        Attribute.codeBlock,
      );
    } else {
      final index = widget.controller.selection.start;
      widget.controller.document.insert(index, '\n$_zeroWidthSpace');
      widget.controller.document.format(index + 1, 1, Attribute.codeBlock);
      widget.controller.updateSelection(
        TextSelection.collapsed(offset: index + 2),
        ChangeSource.local,
      );
    }
    ref
        .read(pageViewModelProvider({
      'groupId': widget.groupId,
      'noteId': widget.noteId,
      'pageId': widget.pageId,
    }).notifier)
        .saveToFirestore(widget.controller);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_scrollController.hasClients) {
      ref.read(toolbarScrollOffsetProvider.notifier).state =
          _scrollController.offset;
    }
    _scrollController.dispose();
    _overlayEntry?.remove();
    _colorOverlayEntry?.remove();
    _highlightOverlayEntry?.remove();
    widget.controller.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingViewModelProvider);
    final recordingViewModel = ref.read(recordingViewModelProvider.notifier);

    return Container(
      width: double.infinity,
      color: Colors.grey[200],
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        child: Row(
          children: [
            if (widget.role == 'owner')
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: recordingState.isRecording
                        ? SvgPicture.asset(
                      'assets/icons/Stop.svg',
                      colorFilter:
                      ColorFilter.mode(Colors.red, BlendMode.srcIn),
                    )
                        : SvgPicture.asset(
                      'assets/icons/Mic.svg',
                      colorFilter:
                      ColorFilter.mode(Colors.black, BlendMode.srcIn),
                    ),
                    onPressed: () async {
                      if (recordingState.isRecording) {
                        await recordingViewModel.stopRecording();
                        ref
                            .read(recordingBoxVisibilityProvider.notifier)
                            .state = true;
                      } else {
                        await recordingViewModel.startRecording();
                      }
                      setState(() {});
                    },
                  ),
                  if (recordingState.isRecording)
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                        _formatDuration(recordingState.recordingDuration),
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/Camera.svg',
                colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                showModalBottomSheet(
                  context: context,
                  builder: (context) => CameraSelectionDialog(
                    groupId: widget.groupId,
                    noteId: widget.noteId,
                    pageId: widget.pageId,
                    controller: widget.controller,
                  ),
                );
              },
            ),
            CompositedTransformTarget(
              link: _layerLink,
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/Fontsize.svg',
                  colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                onPressed: () => _toggleDropdown(context),
              ),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/Bold.svg',
                colorFilter: ColorFilter.mode(
                  _isFormatActive(Attribute.bold)
                      ? Color(0xFF61CFB2)
                      : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                _toggleFormat(Attribute.bold);
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/Italic.svg',
                colorFilter: ColorFilter.mode(
                  _isFormatActive(Attribute.italic)
                      ? Color(0xFF61CFB2)
                      : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                _toggleFormat(Attribute.italic);
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/Underline.svg',
                colorFilter: ColorFilter.mode(
                  _isFormatActive(Attribute.underline)
                      ? Color(0xFF61CFB2)
                      : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                _toggleFormat(Attribute.underline);
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/TextStrikethrough.svg',
                colorFilter: ColorFilter.mode(
                  _isFormatActive(Attribute.strikeThrough)
                      ? Color(0xFF61CFB2)
                      : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                _toggleFormat(Attribute.strikeThrough);
              },
            ),
            CompositedTransformTarget(
              link: _colorLayerLink,
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/Palette.svg',
                  colorFilter: ColorFilter.mode(
                    _isColorPickerOpen ? Color(0xFF61CFB2) : Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () => _toggleColorPicker(context),
              ),
            ),
            CompositedTransformTarget(
              link: _highlightLayerLink,
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/Highlight.svg',
                  colorFilter: ColorFilter.mode(
                    _isHighlightPickerOpen ? Color(0xFF61CFB2) : Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () => _toggleHighlightPicker(context),
              ),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/TextAlignLeft.svg',
                colorFilter: ColorFilter.mode(
                  _isAlignActive('left') ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                _toggleAlign('left');
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/TextAlignCenter.svg',
                colorFilter: ColorFilter.mode(
                  _isAlignActive('center') ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                _toggleAlign('center');
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/TextAlignRight.svg',
                colorFilter: ColorFilter.mode(
                  _isAlignActive('right') ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                _toggleAlign('right');
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/TextAlignJustify.svg',
                colorFilter: ColorFilter.mode(
                  _isAlignActive('justify') ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                _toggleAlign('justify');
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/NumberStyleTable.svg',
                colorFilter: ColorFilter.mode(
                  _isListActive('ordered') ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                _toggleList('ordered');
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/DotStyleTable.svg',
                colorFilter: ColorFilter.mode(
                  _isListActive('bullet') ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                _toggleList('bullet');
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/CheckStyleTable.svg',
                colorFilter: ColorFilter.mode(
                  _isListActive('checked') ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                _toggleList('checked');
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/Code.svg',
                colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
                _insertCodeBlock();
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/Table.svg',
                colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
              onPressed: () {
                ref.read(recordingBoxVisibilityProvider.notifier).state = false;
              },
            ),
          ],
        ),
      ),
    );
  }
}