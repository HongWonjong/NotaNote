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
  final FocusNode _tagFocusNode = FocusNode();
  bool _isLoading = true;
  String? _selectedTag;
  bool _isEditingNewTag = false;

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
    _tagFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addTag(String tag) async {
    if (!mounted) return;
    print('Attempting to add tag: $tag');
    final tags = ref.read(tagListProvider);
    if (tag.isNotEmpty && tags.length < 3) {
      await ref.read(tagViewModelProvider({'groupId': widget.groupId, 'noteId': widget.noteId}).notifier).addTag(tag);
      if (mounted) {
        setState(() {
          _isEditingNewTag = false;
          _tagController.clear();
        });
      }
    } else if (tags.length >= 3) {
      print('Maximum 3 tags reached');
      if (mounted) {
        setState(() {
          _isEditingNewTag = false;
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

  void _requestFocus() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isEditingNewTag && mounted) {
          FocusScope.of(context).requestFocus(_tagFocusNode);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagListProvider);
    print('Building TagWidget, tags: $tags');

    if (_isEditingNewTag) {
      _requestFocus();
    }

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      if (tags.isEmpty && !_isEditingNewTag)
                        GestureDetector(
                          onTap: () {
                            if (mounted) {
                              setState(() {
                                _isEditingNewTag = true;
                              });
                            }
                          },
                          child: Chip(
                            side: BorderSide.none,
                            label: Text(
                              '#해시태그는 최대 3개까지 입력 가능해요',
                              style: TextStyle(
                                color: Color(0xFFB3B3B3),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Color(0xFFF1F1F1),
                          ),
                        ),
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
                                side: BorderSide.none,
                                label: Text(

                                  tag,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF184E40),
                                  ),
                                ),
                                backgroundColor: const Color(0xFFD8F3EC),
                              ),
                              if (isSelected)
                                Positioned(
                                  right: -8.0,
                                  top: -8.0,
                                  child: Container(
                                    width: 24.0,
                                    height: 24.0,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        print('X button tapped for tag: $tag');
                                        _removeTag(tag);
                                      },
                                      child: const Center(
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (_isEditingNewTag)
                        Chip(
                          side: BorderSide.none,
                          label: SizedBox(
                            width: 100,
                            height: 40,
                            child: TextField(
                              controller: _tagController,
                              focusNode: _tagFocusNode,
                              autofocus: true,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF184E40),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '태그 입력',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                              ),
                              onSubmitted: _addTag,
                            ),
                          ),
                          backgroundColor: Color(0xFFD8F3EC),
                          padding: EdgeInsets.zero,
                        ),
                      if (tags.isNotEmpty && tags.length < 3 && !_isEditingNewTag)
                        Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: const ShapeDecoration(
                              color: Color(0xFFD8F3EC),
                              shape: CupertinoRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(6)),
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add, size: 16.0, color: Color(0xFF184E40)),
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    _isEditingNewTag = true;
                                  });
                                }
                              },
                              constraints: const BoxConstraints(),
                            ),
                          ),)
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