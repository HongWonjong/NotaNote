import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/memo.dart';
import 'package:nota_note/models/sort_options.dart';
import 'package:nota_note/viewmodels/memo_viewmodel.dart';
import 'memo_group_app_bar.dart';
import 'package:nota_note/pages/memo_page/memo_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

String trimTitleForDisplay(String title, int maxLength) {
  if (title.length <= maxLength) {
    return title;
  } else {
    return title.substring(0, maxLength) + '...';
  }
}

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

  final query = searchText.toLowerCase();

  return memos.where((memo) {
    final titleMatch = memo.title.toLowerCase().contains(query);
    final tagMatch = memo.tags.any((tag) => tag.toLowerCase().contains(query));
    return titleMatch || tagMatch;
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
  TextSpan _highlightSearchText(String text, String query) {
  if (query.isEmpty) return TextSpan(
    text: text,
    style: const TextStyle(
      color: Color(0xFF191919),
      fontSize: 16,
      fontFamily: 'Pretendard',
      height: 0.09,
    ),
  );

  final matches = <TextSpan>[];
  final pattern = RegExp(RegExp.escape(query), caseSensitive: false);
  int start = 0;

  pattern.allMatches(text).forEach((match) {
    if (match.start > start) {
      matches.add(TextSpan(
        text: text.substring(start, match.start),
        style: const TextStyle(
          color: Color(0xFF191919),
          fontSize: 16,
          fontFamily: 'Pretendard',
          height: 0.09,
        ),
      ));
    }

    matches.add(TextSpan(
      text: text.substring(match.start, match.end),
      style: const TextStyle(
        color: Color(0xFF3BC49F), // 강조 색상
        fontSize: 16,
        fontFamily: 'Pretendard',
        height: 0.09,
      ),
    ));

    start = match.end;
  });

  if (start < text.length) {
    matches.add(TextSpan(
      text: text.substring(start),
      style: const TextStyle(
        color: Color(0xFF191919),
        fontSize: 16,
        fontFamily: 'Pretendard',
        height: 0.09,
      ),
    ));
  }

  return TextSpan(children: matches);
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

  Widget buildCheckCircle() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelectedForDelete ? Color(0xFF61CFB2) : Colors.transparent,
        border: Border.all(
          color: Color(0xFF61CFB2),
          width: 2,
        ),
      ),
      child: isSelectedForDelete
          ? Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }

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
    child: isGrid
    ? Container(
        width: double.infinity,
  constraints: BoxConstraints(minHeight: 170),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Color(0xFFF0F0F0)),
            top: BorderSide(width: 1, color: Color(0xFFF0F0F0)),
            right: BorderSide(color: Color(0xFFF0F0F0)),
            bottom: BorderSide(width: 1, color: Color(0xFFF0F0F0)),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Flexible(
  child: Text.rich(
    _highlightSearchText(
      trimTitleForDisplay(memo.title, 10),
      searchText,
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
),
      const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          height: 55,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (memo.tags.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
  height: 26,
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: ShapeDecoration(
    color: (searchText.isNotEmpty &&
            memo.tags.isNotEmpty &&
            memo.tags[0].contains(searchText))
        ? Color(0xFFB1E7D9)
        : Color(0xFFF0F0F0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: (searchText.isNotEmpty &&
                memo.tags.isNotEmpty &&
                memo.tags[0].contains(searchText))
            ? Color(0xFF61CFB2)
            : Colors.transparent,
        width: 1,
      ),
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        '${memo.tags[0]}',
        style: TextStyle(
          color: Color(0xFF191919),
          fontSize: 12,
          fontFamily: 'Pretendard',
          height: 0.12,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ],
  ),
),

                                    if (memo.tags.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Text(
                                          '+${memo.tags.length - 1}',
                                          style: TextStyle(
                                            color: Color(0xFF7F7F7F),
                                            fontSize: 12,
                                            fontFamily: 'Pretendard',
                                            height: 0.12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      formatTimeAgo(memo.updatedAt),
                                      style: TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 14,
                                        fontFamily: 'Pretendard',
                                        height: 0.11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isDeleteMode)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    toggleSelectForDelete(memo.noteId);
                  },
                  child: buildCheckCircle(),
                ),
              ),
          ],
        ),
      )
    : Container(
      constraints: BoxConstraints(minHeight: 130),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(width: 1, color: Color(0xFFF0F0F0)),
          ),
        ),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     Text.rich(
  _highlightSearchText(memo.title, searchText),
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
),
                      const SizedBox(height: 16),
                      if (memo.tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: memo.tags.take(3).map((tag) {
                            final bool isHighlighted = searchText.isNotEmpty && tag.contains(searchText);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: ShapeDecoration(
                                color: isHighlighted ? Color(0xFFB1E7D9) : Color(0xFFF0F0F0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isHighlighted ? Color(0xFF61CFB2) : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: Color(0xFF191919),
                                  fontSize: 12,
                                  fontFamily: 'Pretendard',
                                  height: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        formatTimeAgo(memo.updatedAt),
                        style: TextStyle(
                          color: Color(0xFF191919),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isDeleteMode)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    toggleSelectForDelete(memo.noteId);
                  },
                  child: buildCheckCircle(),
                ),
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
              childAspectRatio: 1.5,
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
    groupId: widget.groupId, // 여기 꼭 추가
    groupName: widget.groupName,
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

    onSearchChanged: (String value) {
      // 예) setState(() => _searchQuery = value);
      // 또는 원하는 검색어 처리 함수 호출
    },
  ),
  body: Column(
    children: [
      Expanded(child: content),
    ],
  ),
  floatingActionButton: isDeleteMode
    ? null
    : RawMaterialButton(
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
        constraints: BoxConstraints.tightFor(
          width: 70,
          height: 70,
        ),
        shape: CircleBorder(),
        fillColor: Color(0xFF61CFB2),
        elevation: 6,
        child: SvgPicture.asset(
          'assets/icons/FilePlus.svg',
          width: 28,
          height: 28,
          color: Colors.white,
        ),
      ),
);
      },
    );
  }
}