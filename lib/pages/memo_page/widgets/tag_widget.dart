import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/note_viewmodel.dart';
import 'package:cupertino_rrect/cupertino_rrect.dart';

class TagWidget extends ConsumerStatefulWidget {
  final String groupId;
  final String noteId;

  TagWidget({required this.groupId, required this.noteId});

  @override
  _TagWidgetState createState() => _TagWidgetState();
}

class _TagWidgetState extends ConsumerState<TagWidget> {
  final TextEditingController _tagController = TextEditingController();
  bool _isAddingTag = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(noteViewModelProvider({'groupId': widget.groupId, 'noteId': widget.noteId}).notifier).loadFromFirestore();
      }
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !tag.startsWith('#')) {
      tag = '#$tag';
    }
    if (tag.length > 1) {
      ref.read(noteViewModelProvider({'groupId': widget.groupId, 'noteId': widget.noteId}).notifier).addTag(tag);
      _tagController.clear();
      setState(() {
        _isAddingTag = false;
      });
    }
  }

  void _removeTag(String tag) {
    ref.read(noteViewModelProvider({'groupId': widget.groupId, 'noteId': widget.noteId}).notifier).removeTag(tag);
  }

  @override
  Widget build(BuildContext context) {
    final note = ref.watch(noteViewModelProvider({'groupId': widget.groupId, 'noteId': widget.noteId}));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note != null)
            if (note.tags.isNotEmpty)
              Wrap(
                spacing: 8.0,
                children: note.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: Icon(Icons.close, size: 16.0),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: Colors.grey[200],
                  );
                }).toList(),
              ),
          if (_isAddingTag)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: '태그 입력 (예: #프로젝트)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    ),
                    onSubmitted: _addTag,
                    autofocus: true,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () => _addTag(_tagController.text),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isAddingTag = false;
                      _tagController.clear();
                    });
                  },
                ),
              ],
            )
          else if (note == null || note.tags.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: ShapeDecoration(
                  color: Colors.grey[200],
                  shape: CupertinoRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: TextButton.icon(
                  icon: Icon(Icons.add, size: 20.0),
                  label: Text(
                    '해시태그를 입력해주세요',
                    style: TextStyle(fontSize: 16.0, color: Colors.grey),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  ),
                  onPressed: () {
                    setState(() {
                      _isAddingTag = true;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}