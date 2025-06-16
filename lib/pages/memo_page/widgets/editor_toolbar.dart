import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:nota_note/providers/recording_box_visibility_provider.dart';
import 'package:nota_note/viewmodels/image_upload_viewmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'camera_selection_dialog.dart';
import 'color_picker_widget.dart';
import 'highlight_picker_widget.dart';

class EditorToolbar extends ConsumerStatefulWidget {
  final QuillController controller;
  final String groupId;
  final String noteId;
  final String pageId;

  EditorToolbar({
    required this.controller,
    required this.groupId,
    required this.noteId,
    required this.pageId,
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

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
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
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleColorPicker(BuildContext context) {
    if (_isColorPickerOpen) {
      _colorOverlayEntry?.remove();
      _colorOverlayEntry = null;
      _isColorPickerOpen = false;
    } else {
      _colorOverlayEntry = _createColorOverlayEntry(context);
      Overlay.of(context).insert(_colorOverlayEntry!);
      _isColorPickerOpen = true;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleHighlightPicker(BuildContext context) {
    if (_isHighlightPickerOpen) {
      _highlightOverlayEntry?.remove();
      _highlightOverlayEntry = null;
      _isHighlightPickerOpen = false;
    } else {
      _highlightOverlayEntry = _createHighlightOverlayEntry(context);
      Overlay.of(context).insert(_highlightOverlayEntry!);
      _isHighlightPickerOpen = true;
    }
    if (mounted) {
      setState(() {});
    }
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
                  return _buildFontSizeOption(context, option['label'] as String, option['size'] as double);
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
        width: 274.0,
        child: CompositedTransformFollower(
          link: _colorLayerLink,
          showWhenUnlinked: false,
          offset: Offset(-100, -65),
          child: ColorPickerWidget(
            controller: widget.controller,
            onClose: () => _toggleColorPicker(context),
          ),
        ),
      ),
    );
  }

  OverlayEntry _createHighlightOverlayEntry(BuildContext context) {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 274.0,
        child: CompositedTransformFollower(
          link: _highlightLayerLink,
          showWhenUnlinked: false,
          offset: Offset(-100, -65),
          child: HighlightPickerWidget(
            controller: widget.controller,
            onClose: () => _toggleHighlightPicker(context),
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
          onTapDown: (_) {
            setState(() {
              isPressed = true;
            });
          },
          onTapCancel: () {
            setState(() {
              isPressed = false;
            });
          },
          onTap: () async {
            setState(() {
              isPressed = true;
            });
            final selection = widget.controller.selection;
            if (selection.isValid) {
              widget.controller.formatText(
                selection.start,
                selection.end - selection.start,
                Attribute.fromKeyValue('size', size.toInt()),
              );
            }
            await Future.delayed(Duration(milliseconds: 100));
            setState(() {
              isPressed = false;
            });
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
                style: TextStyle(
                  fontSize: size,
                  color: Colors.black,
                ),
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
    return style.attributes.containsKey(attribute.key) && style.attributes[attribute.key]!.value != null;
  }

  bool _isListActive(String listType) {
    final style = widget.controller.getSelectionStyle();
    return style.attributes.containsKey(Attribute.list.key) && style.attributes[Attribute.list.key]!.value == listType;
  }

  bool _isAlignActive(String alignType) {
    final style = widget.controller.getSelectionStyle();
    return style.attributes.containsKey(Attribute.align.key) && style.attributes[Attribute.align.key]!.value == alignType;
  }

  void _toggleFormat(Attribute attribute) {
    final isActive = _isFormatActive(attribute);
    widget.controller.formatSelection(isActive ? Attribute.clone(attribute, null) : attribute);
    if (mounted) {
      setState(() {});
    }
  }

  void _increaseIndent() {
    final selection = widget.controller.selection;
    if (selection.isValid) {
      final style = widget.controller.getSelectionStyle();
      final currentIndent = style.attributes['indent']?.value as int? ?? 0;
      widget.controller.formatSelection(Attribute.fromKeyValue('indent', currentIndent + 1));
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _decreaseIndent() {
    final selection = widget.controller.selection;
    if (selection.isValid) {
      final style = widget.controller.getSelectionStyle();
      final currentIndent = style.attributes['indent']?.value as int? ?? 0;
      if (currentIndent > 0) {
        widget.controller.formatSelection(Attribute.fromKeyValue('indent', currentIndent - 1));
      } else {
        widget.controller.formatSelection(Attribute.clone(Attribute.indent, null));
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _toggleList(String listType) {
    final isActive = _isListActive(listType);
    widget.controller.formatSelection(isActive ? Attribute.clone(Attribute.list, null) : Attribute.fromKeyValue('list', listType));
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleAlign(String alignType) {
    final isActive = _isAlignActive(alignType);
    widget.controller.formatSelection(isActive ? Attribute.clone(Attribute.align, null) : Attribute.fromKeyValue('align', alignType));
    if (mounted) {
      setState(() {});
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
      widget.controller.document.insert(index, '\n');
      widget.controller.document.format(index, 1, Attribute.codeBlock);
      widget.controller.updateSelection(
        TextSelection.collapsed(offset: index + 1),
        ChangeSource.local,
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _colorOverlayEntry?.remove();
    _highlightOverlayEntry?.remove();
    widget.controller.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingViewModelProvider);

    return Container(
      width: double.infinity,
      color: Colors.grey[200],
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: recordingState.isRecording
                      ? SvgPicture.asset(
                    'assets/icons/Stop.svg',
                    colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                  )
                      : SvgPicture.asset(
                    'assets/icons/Mic.svg',
                    colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                  ),
                  onPressed: () async {
                    final recordingViewModel = ref.read(recordingViewModelProvider.notifier);
                    if (recordingState.isRecording) {
                      await recordingViewModel.stopRecording();
                      ref.read(recordingBoxVisibilityProvider.notifier).state = true;
                    } else {
                      await recordingViewModel.startRecording();
                    }
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
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/Link.svg',
                colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
              onPressed: () {},
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
                  _isFormatActive(Attribute.bold) ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => _toggleFormat(Attribute.bold),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/Italic.svg',
                colorFilter: ColorFilter.mode(
                  _isFormatActive(Attribute.italic) ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => _toggleFormat(Attribute.italic),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/Underline.svg',
                colorFilter: ColorFilter.mode(
                  _isFormatActive(Attribute.underline) ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => _toggleFormat(Attribute.underline),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/TextStrikethrough.svg',
                colorFilter: ColorFilter.mode(
                  _isFormatActive(Attribute.strikeThrough) ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => _toggleFormat(Attribute.strikeThrough),
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
              onPressed: () => _toggleAlign('left'),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/TextAlignCenter.svg',
                colorFilter: ColorFilter.mode(
                  _isAlignActive('center') ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => _toggleAlign('center'),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/TextAlignRight.svg',
                colorFilter: ColorFilter.mode(
                  _isAlignActive('right') ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => _toggleAlign('right'),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/TextAlignJustify.svg',
                colorFilter: ColorFilter.mode(
                  _isAlignActive('justify') ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => _toggleAlign('justify'),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/NumberStyleTable.svg',
                colorFilter: ColorFilter.mode(
                  _isListActive('ordered') ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => _toggleList('ordered'),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/DotStyleTable.svg',
                colorFilter: ColorFilter.mode(
                  _isListActive('bullet') ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => _toggleList('bullet'),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/CheckStyleTable.svg',
                colorFilter: ColorFilter.mode(
                  _isListActive('checked') ? Color(0xFF61CFB2) : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => _toggleList('checked'),
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/Code.svg',
                colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
              onPressed: _insertCodeBlock,
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/Table.svg',
                colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}