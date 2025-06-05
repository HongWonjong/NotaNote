import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/viewmodels/tag_viewmodel.dart';
import 'package:cupertino_rrect/cupertino_rrect.dart';

class TagWidget extends ConsumerStatefulWidget {
  final String groupId;
  final String noteId;

  TagWidget({super.key, required this.groupId, required this.noteId});

  @override
  _TagWidgetState createState() => _TagWidgetState();
}

class _TagWidgetState extends ConsumerState<TagWidget> {
  final TextEditingController _tagController = TextEditingController();
  bool _isAddingTag = false;
  bool _isLoading = true;
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('Initializing TagWidget for groupId: ${widget.groupId}, noteId: ${widget.noteId}');
        ref.read(tagViewModelProvider({'groupId': widget.groupId, 'noteId': widget.noteId}).notifier).loadTags().then((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    if (!mounted) return;
    print('Attempting to add tag: $tag');
    if (tag.isNotEmpty) {
      ref.read(tagViewModelProvider({'groupId': widget.groupId, 'noteId': widget.noteId}).notifier).addTag(tag);
      if (mounted) {
        setState(() {
          _isAddingTag = false;
          _tagController.clear();
        });
      }
    } else {
      print('Tag is empty');
    }
  }

  void _removeTag(String tag) {
    if (!mounted) return;
    print('X button clicked for tag: $tag');
    ref.read(tagViewModelProvider({'groupId': widget.groupId, 'noteId': widget.noteId}).notifier).removeTag(tag);
    if (mounted) {
      setState(() {
        _selectedTag = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagListProvider);
    print('Building TagWidget, tags: $tags');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: [
                          ...tags.map((tag) {
                            final isSelected = _selectedTag == tag;
                            return GestureDetector(
                              onTap: () {
                                if (mounted) {
                                  print('Tag clicked: $tag');
                                  setState(() {
                                    _selectedTag = isSelected ? null : tag;
                                  });
                                }
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    backgroundColor: Colors.grey[200],
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      right: -8.0,
                                      top: -8.0,
                                      child: GestureDetector(
                                        onTap: () {
                                          print('X button tapped for tag: $tag');
                                          _removeTag(tag);
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          Container(
                            decoration: ShapeDecoration(
                              color: Colors.grey[200],
                              shape: const CupertinoRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(6)),
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add, size: 20.0, color: Colors.black),
                              onPressed: () {
                                print('Tag add button pressed');
                                if (mounted) {
                                  setState(() {
                                    _isAddingTag = true;
                                  });
                                }
                              },
                              padding: const EdgeInsets.all(4.0),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isAddingTag)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            decoration: const InputDecoration(
                              hintText: '해시태그를 입력해주세요',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            ),
                            onSubmitted: _addTag,
                            autofocus: true,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () => _addTag(_tagController.text),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            if (mounted) {
                              setState(() {
                                _isAddingTag = false;
                                _tagController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}