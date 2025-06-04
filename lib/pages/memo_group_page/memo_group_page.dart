import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nota_note/pages/memo_page/memo_page.dart';


enum SortOption { dateDesc, dateAsc, titleAsc }

class MemoGroupPage extends StatefulWidget {
  const MemoGroupPage({super.key});

  @override
  State<MemoGroupPage> createState() => _MemoGroupPageState();
}

class _MemoGroupPageState extends State<MemoGroupPage> {
  bool isGrid = true;
  bool isSearching = false;
  bool isDeleteMode = false;
  Set<int> selectedForDelete = {};

  SortOption sortOption = SortOption.dateDesc;

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> dummyMemos = [
    {
      'title': '첫 번째 메모 제목',
      'date': '2025.06.02',
      'tags': ['플러터', '메모', '첫번째']
    },
    {
      'title': '두 번째 메모 제목',
      'date': '2025.06.01',
      'tags': ['다트', '메모', '두번째']
    },
    {
      'title': '세 번째 메모 제목',
      'date': '2025.05.30',
      'tags': ['플러터', '리스트', '세번째']
    },
    {
      'title': '검색 테스트 메모',
      'date': '2025.05.29',
      'tags': ['검색', '테스트', '플러터']
    },
  ];

  List<Map<String, dynamic>> filteredMemos = [];

  @override
  void initState() {
    super.initState();
    filteredMemos = [];

    _searchController.addListener(() {
      _filterMemos(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMemos(String query) {
    final q = query.trim().toLowerCase();

    setState(() {
      if (q.isEmpty) {
        filteredMemos = [];
      } else {
        filteredMemos = dummyMemos.where((memo) {
          final tags = (memo['tags'] as List<dynamic>)
              .map((e) => e.toString().toLowerCase())
              .toList();
          return tags.any((tag) => tag.contains(q));
        }).toList();
      }
      isDeleteMode = false;
      selectedForDelete.clear();
    });
  }

  List<Map<String, dynamic>> _applySorting(List<Map<String, dynamic>> list) {
    List<Map<String, dynamic>> sortedList = List.from(list);

    int dateToInt(String dateStr) {
      return int.tryParse(dateStr.replaceAll('.', '')) ?? 0;
    }

    switch (sortOption) {
      case SortOption.dateDesc:
        sortedList.sort((a, b) =>
            dateToInt(b['date']).compareTo(dateToInt(a['date'])));
        break;
      case SortOption.dateAsc:
        sortedList.sort((a, b) =>
            dateToInt(a['date']).compareTo(dateToInt(b['date'])));
        break;
      case SortOption.titleAsc:
        sortedList.sort((a, b) =>
            (a['title'] as String).compareTo(b['title'] as String));
        break;
    }
    return sortedList;
  }

  Widget _buildMemoItem(Map<String, dynamic> memo, int index) {
    final isSelectedForDelete = selectedForDelete.contains(index);

    return GestureDetector(
      onTap: () {
        if (isDeleteMode) {
          setState(() {
            if (isSelectedForDelete) {
              selectedForDelete.remove(index);
            } else {
              selectedForDelete.add(index);
            }
          });
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
            Text(memo['title'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(memo['date'] ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (memo['tags'] as List<String>)
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black87),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (isSearching) {
      return AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            setState(() {
              isSearching = false;
              _searchController.clear();
              filteredMemos = [];
              isDeleteMode = false;
              selectedForDelete.clear();
            });
          },
        ),
        title: Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  cursorColor: Colors.black,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: '태그로 검색',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              '총 ${filteredMemos.length}개',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    return AppBar(
      title: const Text('메모 그룹'),
      leading: isDeleteMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isDeleteMode = false;
                  selectedForDelete.clear();
                });
              },
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              isSearching = true;
              filteredMemos = [];
              _searchController.clear();
              isDeleteMode = false;
              selectedForDelete.clear();
            });
          },
        ),

        // 기존 설정 메뉴 + 정렬 메뉴 통합
        _buildSettingsMenu(),

        if (isDeleteMode)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: selectedForDelete.isEmpty
                ? null
                : () {
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
                                dummyMemos = dummyMemos
                                    .asMap()
                                    .entries
                                    .where((entry) => !selectedForDelete.contains(entry.key))
                                    .map((entry) => entry.value)
                                    .toList();
                                filteredMemos = [];
                                selectedForDelete.clear();
                                isDeleteMode = false;
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );
                  },
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(24),
        child: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            '총 ${isSearching ? filteredMemos.length : dummyMemos.length}개',
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  // 설정 메뉴에 정렬 옵션 포함
  Widget _buildSettingsMenu() {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert),
      tooltip: '설정 메뉴',
      onSelected: (value) {
        switch (value) {
          case 1:
            _showSharingSettings();
            break;
          case 2:
            _showSortOptionsDialog();
            break;
          case 3:
            setState(() {
              isDeleteMode = true;
              selectedForDelete.clear();
            });
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 1,
          child: ListTile(
            leading: Icon(Icons.share),
            title: Text('공유'),
          ),
        ),
        const PopupMenuItem(
          value: 2,
          child: ListTile(
            leading: Icon(Icons.sort),
            title: Text('정렬'),
          ),
        ),
        PopupMenuItem(
          enabled: false,
          child: GestureDetector(
            onTap: () {
              setState(() {
                isGrid = !isGrid;
              });
              Navigator.of(context).pop();
            },
            child: Row(
              children: [
                Icon(isGrid ? Icons.view_list : Icons.grid_view),
                const SizedBox(width: 8),
                Text(isGrid ? '목록으로 보기' : '갤러리로 보기'),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 3,
          child: ListTile(
            leading: Icon(Icons.delete),
            title: Text('삭제'),
          ),
        ),
      ],
    );
  }

  // 정렬 옵션 선택 다이얼로그
  void _showSortOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('정렬 옵션'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<SortOption>(
                title: const Text('수정일'),
                value: SortOption.dateDesc,
                groupValue: sortOption,
                onChanged: (value) {
                  setState(() {
                    sortOption = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<SortOption>(
                title: const Text('생성일'),
                value: SortOption.dateAsc,
                groupValue: sortOption,
                onChanged: (value) {
                  setState(() {
                    sortOption = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<SortOption>(
                title: const Text('제목 오름차순'),
                value: SortOption.titleAsc,
                groupValue: sortOption,
                onChanged: (value) {
                  setState(() {
                    sortOption = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSharingSettings() {
    // 공유 설정 다이얼로그 간단히 구현
    showDialog(
      context: context,
      builder: (context) {
        String selectedPermission = '읽기 전용';
        const String ownerName = '홍길동';

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('공유 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('소유자: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(ownerName),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('권한'),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('읽기 전용'),
                          value: '읽기 전용',
                          groupValue: selectedPermission,
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedPermission = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('읽기 및 편집'),
                          value: '읽기 및 편집',
                          groupValue: selectedPermission,
                          onChanged: (value) {
                            setStateDialog(() {
                              selectedPermission = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBody() {
    List<Map<String, dynamic>> showList =
        isSearching ? filteredMemos : dummyMemos;

    showList = _applySorting(showList);

    if (showList.isEmpty) {
      return const Center(child: Text('메모가 없습니다 메모를 작성해 주세요!'));
    }

    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: showList.length,
        itemBuilder: (context, index) {
          return _buildMemoItem(showList[index], index);
        },
      );
    }

    // 목록 보기
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: showList.length,
      itemBuilder: (context, index) {
        return _buildMemoItem(showList[index], index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: isDeleteMode
    ? null
    : FloatingActionButton(
        onPressed: () {
          Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MemoPage(
      groupId: 'testGroupId',
      noteId: 'testNoteId',
      pageId: 'testPageId',
    ),
  ),
);
        },
        child: const Icon(Icons.add),
      ),
      ),
    );
  }
}
