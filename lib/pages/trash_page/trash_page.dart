import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/memo.dart';
import 'package:nota_note/theme/pretendard_text_styles.dart';
import 'package:nota_note/viewmodels/memo_viewmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TrashPage extends ConsumerStatefulWidget {
  final String groupId;
  const TrashPage({Key? key, required this.groupId}) : super(key: key);

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  bool isEditMode = false;
  Set<String> selectedNoteIds = {};

  @override
  Widget build(BuildContext context) {
    final memoViewModel = ref.watch(memoViewModelProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('휴지통',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                isEditMode = !isEditMode;
                if (!isEditMode) selectedNoteIds.clear();
              });
            },
            child: Text(isEditMode ? '완료' : '편집',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('총 ${selectedNoteIds.length}개',
                    style: PretendardTextStyles.bodyM),
                if (isEditMode)
                  GestureDetector(
                    onTap: () {
                      _showDeleteConfirmDialog(context);
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFEEEE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/icons/trash_red_icon.svg',
                            width: 16,
                            height: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '비우기',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Memo>>(
              stream: memoViewModel.deletedMemosStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                }

                final memos = snapshot.data ?? [];

                if (memos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('휴지통이 비어있습니다',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: memos.length,
                  itemBuilder: (context, index) {
                    final memo = memos[index];
                    final isSelected = selectedNoteIds.contains(memo.noteId);

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFEEEEEE), width: 1),
                        ),
                      ),
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: isEditMode
                            ? GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedNoteIds.remove(memo.noteId);
                                    } else {
                                      selectedNoteIds.add(memo.noteId);
                                    }
                                  });
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Color(0xFF60CFB1)
                                          : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                    color: isSelected
                                        ? Color(0xFF60CFB1)
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              )
                            : null,
                        title: Text(
                          memo.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected ? Color(0xFF60CFB1) : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              memo.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              children: memo.tags
                                  .map((tag) => Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF0F0F0),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '#$tag',
                                          style: PretendardTextStyles.labelS,
                                        ),
                                      ))
                                  .toList(),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '편집된 날짜',
                              style: PretendardTextStyles.labelS
                                  .copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                        onTap: isEditMode
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    selectedNoteIds.remove(memo.noteId);
                                  } else {
                                    selectedNoteIds.add(memo.noteId);
                                  }
                                });
                              }
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: isEditMode
          ? Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: selectedNoteIds.isEmpty
                          ? null
                          : () async {
                              await memoViewModel
                                  .restoreMemos(selectedNoteIds.toList());
                              setState(() => selectedNoteIds.clear());
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('선택한 메모가 복구되었습니다'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                      child: Text(
                        '복구',
                        style: TextStyle(
                          color: selectedNoteIds.isEmpty
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Color(0xFFEEEEEE),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: selectedNoteIds.isEmpty
                          ? null
                          : () {
                              _showDeleteConfirmDialog(context);
                            },
                      child: Text(
                        '삭제',
                        style: TextStyle(
                          color: selectedNoteIds.isEmpty
                              ? Colors.grey
                              : Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('휴지통에 있는 메모를'),
        content: Text('영구적으로 삭제하겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final memoViewModel =
                  ref.read(memoViewModelProvider(widget.groupId));
              await memoViewModel
                  .deleteMemosPermanently(selectedNoteIds.toList());
              setState(() => selectedNoteIds.clear());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('선택한 메모가 영구적으로 삭제되었습니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              '비우기',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
