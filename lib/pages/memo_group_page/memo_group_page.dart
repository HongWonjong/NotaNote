import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/memo.dart';
import 'package:nota_note/models/sort_options.dart';
import 'package:nota_note/viewmodels/memo_viewmodel.dart';
import 'memo_group_app_bar.dart';
import 'package:nota_note/pages/memo_page/memo_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nota_note/utils/view_mode_prefs.dart';

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
  final String role;

  const MemoGroupPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.role,
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
    _loadViewMode();
    _searchController.addListener(() {
      setState(() {
        searchText = _searchController.text;
      });
    });
  }

  Future<void> _loadViewMode() async {
    final saved = await ViewModePrefs.loadIsGrid();
    setState(() {
      isGrid = saved;
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
    ViewModePrefs.saveIsGrid(value);
  }

  List<Memo> getFilteredMemos(List<Memo> memos) {
    if (searchText.isEmpty) return memos;

    final query = searchText.toLowerCase();

    return memos.where((memo) {
      final titleMatch = memo.title.toLowerCase().contains(query);
      final tagMatch =
          memo.tags.any((tag) => tag.toLowerCase().contains(query));
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
    if (query.isEmpty) {
      return TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF191919),
          fontSize: 16,
          fontFamily: 'Pretendard',
          height: 0.09,
        ),
      );
    }

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
          color: Color(0xFF3BC49F),
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
              await ref
                  .read(memoViewModelProvider(widget.groupId))
                  .deleteMemos(selectedForDelete.toList());
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
        color: isSelectedForDelete ? const Color(0xFF61CFB2) : Colors.transparent,
        border: Border.all(
          color: const Color(0xFF61CFB2),
          width: 2,
        ),
      ),
      child: isSelectedForDelete
          ? const Icon(Icons.check, color: Colors.white, size: 16)
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
              role: widget.role, // role 전달 (필요하면)
            ),
          ),
        );
      }
    },
    child: isGrid
        ? Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 16,
              top: isDeleteMode ? 22 : 16,  // 제목 위쪽 여백 조절
            ),
            constraints: const BoxConstraints(minHeight: 260),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                left: BorderSide(color: Color(0xFFF0F0F0)),
                top: BorderSide(width: 1, color: Color(0xFFF0F0F0)),
                right: BorderSide(color: Color(0xFFF0F0F0)),
                bottom: BorderSide(width: 1, color: Color(0xFFF0F0F0)),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: isDeleteMode ? 32 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 6),
                      Text.rich(
  _highlightSearchText(
    trimTitleForDisplay(memo.title, 8),
    searchText,
  ),
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),
const SizedBox(height: 18),
Text(
  memo.content,
  maxLines: 3,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    color: Color(0xFF333333),
    fontSize: 13,
    fontFamily: 'Pretendard',
    height: 1.4,
  ),
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
                                color: isHighlighted ? const Color(0xFFB1E7D9) : const Color(0xFFF0F0F0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
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
                      if (memo.tags.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '+${memo.tags.length - 3}',
                            style: const TextStyle(
                              color: Color(0xFF7F7F7F),
                              fontSize: 12,
                              fontFamily: 'Pretendard',
                              height: 1.2,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        formatTimeAgo(memo.updatedAt),
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDeleteMode)
                  Positioned(
                    top: -12,
                    left: 0,
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
            constraints: const BoxConstraints(minHeight: 130),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 12,
              top: isDeleteMode ? 20 : 12,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(width: 1, color: Color(0xFFF0F0F0)),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: isDeleteMode ? 32 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6),
                      Text.rich(
  _highlightSearchText(
    trimTitleForDisplay(memo.title, 20),
    searchText,
  ),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Colors.black87,
  ),
),
const SizedBox(height: 18),
Text(
  memo.content,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    color: Color(0xFF333333),
    fontSize: 13,
    fontFamily: 'Pretendard',
    height: 1.3,
  ),
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
                                color: isHighlighted ? const Color(0xFFB1E7D9) : const Color(0xFFF0F0F0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
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
                      if (memo.tags.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '+${memo.tags.length - 3}',
                            style: const TextStyle(
                              color: Color(0xFF7F7F7F),
                              fontSize: 12,
                              fontFamily: 'Pretendard',
                              height: 1.2,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        formatTimeAgo(memo.updatedAt),
                        style: const TextStyle(
                          color: Color(0xFF191919),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDeleteMode)
                  Positioned(
                    top: -12,
                    left: 0,
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
                    childAspectRatio: 0.9,
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
            groupId: widget.groupId,
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
            onDeletePressed:
                selectedForDelete.isEmpty ? null : _confirmDeleteDialog,
            onSearchChanged: (String value) {},
            role: widget.role,
          ),
          body: Column(children: [Expanded(child: content)]),
          floatingActionButton: isDeleteMode || widget.role == 'guest'
              ? null
              : RawMaterialButton(
                  onPressed: () async {
                    final memoViewModel =
                        ref.read(memoViewModelProvider(widget.groupId));
                    final newNoteId = await memoViewModel.addMemo();
                    if (newNoteId != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemoPage(
                            groupId: widget.groupId,
                            noteId: newNoteId,
                            pageId: '1',
                            role: widget.role, // role 전달
                          ),
                        ),
                      );
                    }
                  },
                  constraints:
                      const BoxConstraints.tightFor(width: 70, height: 70),
                  shape: const CircleBorder(),
                  fillColor: const Color(0xFF61CFB2),
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
