import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';
import 'package:intl/intl.dart';
import 'package:nota_note/providers/recording_box_visibility_provider.dart';

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
  final LayerLink _layerLink = LayerLink();
  bool _isDropdownOpen = false;
  double _defaultFontSize = 16.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
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
                children: [12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0].map((size) {
                  return GestureDetector(
                    onTap: () {
                      final selection = widget.controller.selection;
                      if (selection.isValid) {
                        widget.controller.formatText(
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
    final selection = widget.controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final style = widget.controller.getSelectionStyle();
      if (style.attributes.containsKey('size')) {
        return (style.attributes['size']!.value as int).toDouble();
      }
    }
    return _defaultFontSize;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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
    setState(() {});
  }

  void _increaseIndent() {
    final selection = widget.controller.selection;
    if (selection.isValid) {
      final style = widget.controller.getSelectionStyle();
      final currentIndent = style.attributes['indent']?.value as int? ?? 0;
      widget.controller.formatSelection(Attribute.fromKeyValue('indent', currentIndent + 1));
      setState(() {});
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
      setState(() {});
    }
  }

  void _toggleList(String listType) {
    final isActive = _isListActive(listType);
    widget.controller.formatSelection(isActive ? Attribute.clone(Attribute.list, null) : Attribute.fromKeyValue('list', listType));
    setState(() {});
  }

  void _toggleAlign(String alignType) {
    final isActive = _isAlignActive(alignType);
    widget.controller.formatSelection(isActive ? Attribute.clone(Attribute.align, null) : Attribute.fromKeyValue('align', alignType));
    setState(() {});
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    widget.controller.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingViewModelProvider);
    final currentFontSize = _getCurrentFontSize();

    return Container(
      width: double.infinity,
      color: Colors.grey[200],
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(recordingState.isRecording ? Icons.stop : Icons.mic_none_rounded),
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
                  Text(
                    _formatDuration(recordingState.recordingDuration),
                    style: TextStyle(fontSize: 12.0, color: Colors.black),
                  ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.camera_alt),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.link),
              onPressed: () {},
            ),
            IconButton(
              icon: Text('가', style: TextStyle(fontSize: 18.0)),
              onPressed: () {},
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
            IconButton(
              icon: Icon(Icons.format_bold),
              color: _isFormatActive(Attribute.bold) ? Colors.blue : null,
              onPressed: () => _toggleFormat(Attribute.bold),
            ),
            IconButton(
              icon: Icon(Icons.format_italic),
              color: _isFormatActive(Attribute.italic) ? Colors.blue : null,
              onPressed: () => _toggleFormat(Attribute.italic),
            ),
            IconButton(
              icon: Icon(Icons.format_underline),
              color: _isFormatActive(Attribute.underline) ? Colors.blue : null,
              onPressed: () => _toggleFormat(Attribute.underline),
            ),
            IconButton(
              icon: Icon(Icons.format_strikethrough),
              color: _isFormatActive(Attribute.strikeThrough) ? Colors.blue : null,
              onPressed: () => _toggleFormat(Attribute.strikeThrough),
            ),
            IconButton(
              icon: Icon(Icons.palette),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.brush),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.format_align_left),
              color: _isAlignActive('left') ? Colors.blue : null,
              onPressed: () => _toggleAlign('left'),
            ),
            IconButton(
              icon: Icon(Icons.format_align_center),
              color: _isAlignActive('center') ? Colors.blue : null,
              onPressed: () => _toggleAlign('center'),
            ),
            IconButton(
              icon: Icon(Icons.format_align_right),
              color: _isAlignActive('right') ? Colors.blue : null,
              onPressed: () => _toggleAlign('right'),
            ),
            IconButton(
              icon: Icon(Icons.format_align_justify),
              color: _isAlignActive('justify') ? Colors.blue : null,
              onPressed: () => _toggleAlign('justify'),
            ),
            IconButton(
              icon: Icon(Icons.format_list_numbered),
              color: _isListActive('ordered') ? Colors.blue : null,
              onPressed: () => _toggleList('ordered'),
            ),
            IconButton(
              icon: Icon(Icons.format_list_bulleted),
              color: _isListActive('bullet') ? Colors.blue : null,
              onPressed: () => _toggleList('bullet'),
            ),
            IconButton(
              icon: Icon(Icons.check_box_outlined),
              color: _isListActive('checked') ? Colors.blue : null,
              onPressed: () => _toggleList('checked'),
            ),
            IconButton(
              icon: Icon(Icons.code),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.table_chart),
              onPressed: () {},
            ),
            IconButton(
              icon: Text('AI'),
              onPressed: () {
                print('AI 버튼 클릭');
              },
            ),
          ],
        ),
      ),
    );
  }
}