import 'package:flutter/material.dart';
import '../../models/memo.dart';
import 'popup_menu.dart'; // SortOption, SettingsMenu 포함
import 'memo_group_app_bar.dart';
import '../../data/dummy_data.dart';

class MemoGroupPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const MemoGroupPage({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<MemoGroupPage> createState() => _MemoGroupPageState();
}


class _MemoGroupPageState extends State<MemoGroupPage> {
  bool isSearching = false;
  bool isDeleteMode = false;
  bool isGrid = false;

  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  SortOption selectedSort = SortOption.dateDesc;

  late List<Memo> memos;

  Set<int> selectedForDelete = {};

  @override
  void initState() {
    super.initState();
    memos = dummyMemos;

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

  List<Memo> get filteredMemos {
    if (searchText.isEmpty) return memos;

    // 태그로만 검색
    return memos.where((memo) {
      return memo.tags.any((tag) => tag.contains(searchText));
    }).toList();
  }

  List<Memo> get sortedMemos {
    List<Memo> temp = List.from(filteredMemos);
    switch (selectedSort) {
      case SortOption.dateDesc:
        temp.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.dateAsc:
        temp.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.titleAsc:
        temp.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
    return temp;
  }

  void toggleSelectForDelete(int index) {
    setState(() {
      if (selectedForDelete.contains(index)) {
        selectedForDelete.remove(index);
      } else {
        selectedForDelete.add(index);
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
            onPressed: () {
              setState(() {
                memos = memos
                    .asMap()
                    .entries
                    .where((entry) => !selectedForDelete.contains(entry.key))
                    .map((entry) => entry.value)
                    .toList();

                selectedForDelete.clear();
                isDeleteMode = false;
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${selectedForDelete.length}개의 메모장이 휴지통으로 이동했습니다.'),
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

  // 날짜를 "n일 전" 식으로 변환하는 함수
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

 Widget _buildMemoCard(int index, bool isGrid) {
  final memo = sortedMemos[index];
  final originalIndex = memos.indexOf(memo);
  final isSelectedForDelete = selectedForDelete.contains(originalIndex);

  return GestureDetector(
    onTap: () {
      if (isDeleteMode) {
        toggleSelectForDelete(originalIndex);
      } else {
        // TODO: 메모 상세 페이지로 이동
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
            isGrid
                ? Row(
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
                  )
                : Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: memo.tags.map((tag) => Chip(label: Text(tag))).toList(),
                  ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    // 검색 중이고 검색어가 비어있으면 메모를 보여주지 않음
    final bool showMemos = !(isSearching && searchText.isEmpty);

    // 현재 보여지는 메모 개수 (검색 중일 때만 필터된 갯수, 아니면 전체)
    final int currentMemoCount = showMemos ? sortedMemos.length : 0;

   Widget content;
if (!showMemos) {
  content = const Center(child: Text('검색어를 입력해주세요.'));
} else if (currentMemoCount == 0) {
  content = const Center(child: Text('검색 결과가 없습니다.'));
} else {
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
          itemBuilder: (context, index) => _buildMemoCard(index, isGrid),
        )
      : ListView.builder(
          itemCount: currentMemoCount,
          itemBuilder: (context, index) => _buildMemoCard(index, isGrid),
        );
}

    return Scaffold(
  appBar: MemoGroupAppBar(
    groupName: widget.groupName,  // 이 부분 꼭 추가
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
    : SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: () {
            // TODO: 메모 작성 페이지로 이동
          },
          backgroundColor: const Color(0xFF61CFB2), // 원형 배경 색상
          elevation: 0,
          shape: const CircleBorder(), // 완전한 원형 보장
          child: Stack(
            alignment: Alignment.center,
            children: const [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 26,
                color: Colors.white, // 아이콘 색상
              ),
              Icon(
                Icons.add,
                size: 14,
                color: Colors.white, // 흰색 + 아이콘을 중앙에
              ),
            ],
          ),
        ),
      ),
    );
  }
}
