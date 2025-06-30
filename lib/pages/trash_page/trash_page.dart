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
  bool selectAll = false;

  @override
  Widget build(BuildContext context) {
    final memoViewModel = ref.watch(memoViewModelProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('휴지통', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                isEditMode = !isEditMode;
                if (!isEditMode) selectedNoteIds.clear();
              });
            },
            child: Text(isEditMode ? '완료' : '편집',
                style: PretendardTextStyles.bodyM),
          ),
        ],
      ),
      body: StreamBuilder<List<Memo>>(
        stream: memoViewModel.deletedMemosStream,
        builder: (context, snapshot) {
          final memos = snapshot.data ?? [];
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('총 ${memos.length}개',
                        style: PretendardTextStyles.bodyM),
                    if (isEditMode)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (selectedNoteIds.length == memos.length) {
                              selectedNoteIds.clear();
                              selectAll = false;
                            } else {
                              selectedNoteIds =
                                  memos.map((m) => m.noteId).toSet();
                              selectAll = true;
                            }
                          });
                        },
                        child: Text('전체 선택', style: PretendardTextStyles.bodyM),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: memos.length,
                  itemBuilder: (context, idx) {
                    final memo = memos[idx];
                    final selected = selectedNoteIds.contains(memo.noteId);
                    return ListTile(
                      leading: isEditMode
                          ? Checkbox(
                              value: selected,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    selectedNoteIds.add(memo.noteId);
                                  } else {
                                    selectedNoteIds.remove(memo.noteId);
                                  }
                                });
                              },
                            )
                          : null,
                      title: Text(memo.title,
                          style: PretendardTextStyles.bodyM.copyWith(
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color:
                                  selected ? Color(0xFF60CFB1) : Colors.black)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(memo.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PretendardTextStyles.bodyS),
                          Wrap(
                            spacing: 4,
                            children: memo.tags
                                .map((tag) => Chip(
                                    label: Text('#$tag',
                                        style: PretendardTextStyles.labelS)))
                                .toList(),
                          ),
                          Text('편집된 날짜',
                              style: PretendardTextStyles.labelS
                                  .copyWith(color: Colors.grey)),
                        ],
                      ),
                      onTap: isEditMode
                          ? () {
                              setState(() {
                                if (selected) {
                                  selectedNoteIds.remove(memo.noteId);
                                } else {
                                  selectedNoteIds.add(memo.noteId);
                                }
                              });
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: isEditMode
          ? BottomAppBar(
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
                            },
                      child: Text('복구', style: PretendardTextStyles.bodyM),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: selectedNoteIds.isEmpty
                          ? null
                          : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  content: Text('휴지통에 있는 메모를 영구적으로 삭제하시겠습니까?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text('취소'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text('비우기',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await memoViewModel.deleteMemosPermanently(
                                    selectedNoteIds.toList());
                                setState(() => selectedNoteIds.clear());
                              }
                            },
                      child: Text('삭제',
                          style: PretendardTextStyles.bodyM
                              .copyWith(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
