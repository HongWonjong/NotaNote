import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/memo.dart';
import 'package:nota_note/models/sort_options.dart';
import 'package:nota_note/viewmodels/memo_viewmodel.dart';
import 'popup_menu.dart';
import 'memo_group_app_bar.dart';
import 'package:nota_note/pages/memo_page/memo_page.dart';

class MemoGroupPage extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const MemoGroupPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<MemoGroupPage> createState() => _MemoGroupPageState();
}

class _MemoGroupPageState extends ConsumerState<MemoGroupPage> {
  bool isSearching = false;
  bool isDeleteMode = false;
  bool isGrid = false;

  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  SortOption selectedSort = SortOption.dateDesc;

  Set<String> selectedForDelete = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void cancelSearch() {
    setState(() {
      isSearching = false;
      _searchController.clear();
      searchText = '';
    });
  }

  void startSearch() {
    setState(() {
      isSearching = true;
      _searchController.clear();
      searchText = '';
      isDeleteMode = false;
      selectedForDelete.clear();
    });
  }

  void cancelDelete() {
    setState(() {
      isDeleteMode = false;
      selectedForDelete.clear();
    });
  }

  void startDeleteMode() {
    setState(() {
      isDeleteMode = true;
      isSearching = false;
      selectedForDelete.clear();
    });
  }

  void updateSort(SortOption option) {
    setState(() {
      selectedSort = option;
    });
  }

  void toggleGridView(bool value) {
    setState(() {
      isGrid = value;
    });
  }

  List<Memo> getFilteredMemos(List<Memo> memos) {
    if (searchText.isEmpty) return memos;
    return memos.where((memo) {
      return memo.tags.any((tag) => tag.contains(searchText));
    }).toList();
  }

  List<Memo> getSortedMemos(List<Memo> memos) {
    List<Memo> temp = List.from(memos);
    temp.sort((a, b) => Memo.compare(a, b, selectedSort));
    return temp;
  }

  void toggleSelectForDelete(String noteId) {
    setState(() {
      if (selectedForDelete.contains(noteId)) {
        selectedForDelete.remove(noteId);
      } else {
        selectedForDelete.add(noteId);
      }
    });
  }

  void _confirmDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('삭제하시겠습니까?'),
        content: Text('${selectedForDelete.length}개의 메모를 삭제합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final count = selectedForDelete.length;
              await ref.read(memoViewModelProvider(widget.groupId)).deleteMemos(selectedForDelete.toList());
              cancelDelete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$count개의 메모장이 휴지통으로 이동했습니다.'),
                  backgroundColor: Colors.black,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays >= 1) {
      return '${diff.inDays}일 전';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}시간 전';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  Widget _buildMemoCard(Memo memo) {
    final isSelectedForDelete = selectedForDelete.contains(memo.noteId);

    return GestureDetector(
      onTap: () {
        if (isDeleteMode) {
          toggleSelectForDelete(memo.noteId);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemoPage(
                groupId: memo.groupId,
                noteId: memo.noteId,
                pageId: '1',
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelectedForDelete ? Colors.red.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: isSelectedForDelete ? Border.all(color: Colors.red, width: 2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(memo.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('생성: ${formatTimeAgo(memo.createdAt)}'),
            const SizedBox(height: 4),
            Text('수정: ${formatTimeAgo(memo.updatedAt)}'),
            const SizedBox(height: 4),
            if (memo.tags.isNotEmpty)
              Row(
                children: [
                  ...memo.tags.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final tag = entry.value;
                    if (idx == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Chip(label: Text(tag)),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  if (memo.tags.length > 1)
                    Text('+${memo.tags.length - 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Memo>>(
      stream: ref.watch(memoViewModelProvider(widget.groupId)).memosStream,
      builder: (context, snapshot) {
        Widget content;
        int currentMemoCount = 0;

        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          content = Center(child: Text('오류: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          content = const Center(child: Text('메모가 없습니다.'));
        } else {
          final memos = getSortedMemos(getFilteredMemos(snapshot.data!));
          currentMemoCount = memos.length;
          content = isGrid
              ? GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: currentMemoCount,
            itemBuilder: (context, index) => _buildMemoCard(memos[index]),
          )
              : ListView.builder(
            itemCount: currentMemoCount,
            itemBuilder: (context, index) => _buildMemoCard(memos[index]),
          );
        }

        return Scaffold(
          appBar: MemoGroupAppBar(
            isSearching: isSearching,
            isDeleteMode: isDeleteMode,
            memoCount: currentMemoCount,
            searchController: _searchController,
            onCancelSearch: cancelSearch,
            onSearchPressed: startSearch,
            onCancelDelete: cancelDelete,
            isGrid: isGrid,
            sortOption: selectedSort,
            onSortChanged: updateSort,
            onDeleteModeStart: startDeleteMode,
            onRename: () {},
            onEditGroup: () {},
            onSharingSettingsToggle: () {},
            onGridToggle: toggleGridView,
            selectedDeleteCount: selectedForDelete.length,
            onDeletePressed: selectedForDelete.isEmpty ? null : _confirmDeleteDialog,
          ),
          body: Column(
            children: [
              Expanded(child: content),
            ],
          ),
          floatingActionButton: isDeleteMode
              ? null
              : FloatingActionButton(
            onPressed: () async {
              final memoViewModel = ref.read(memoViewModelProvider(widget.groupId));
              final newNoteId = await memoViewModel.addMemo();
              if (newNoteId != null && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MemoPage(
                      groupId: widget.groupId,
                      noteId: newNoteId,
                      pageId: '1',
                    ),
                  ),
                );
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}