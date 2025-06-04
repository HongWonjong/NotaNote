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

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingViewModelProvider);
    final currentFontSize = _getCurrentFontSize();

    return Container(
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
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(recordingState.isRecording ? Icons.stop : Icons.mic),
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
                widget.controller.formatSelection(Attribute.bold);
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
    );
  }
}