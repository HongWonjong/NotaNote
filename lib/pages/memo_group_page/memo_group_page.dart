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
    filteredMemos = List.from(dummyMemos);

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
  final List<String> tags = List<String>.from(memo['tags'] ?? []);
  final int tagCount = tags.length;

  List<Widget> tagWidgets = [];

  if (tagCount > 0) {
    // 첫 번째 태그
    tagWidgets.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black87),
        ),
        child: Text(
          '#${tags[0]}',
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ),
    );

    // +n 텍스트 (배경, 테두리 없이)
    if (tagCount > 1) {
      tagWidgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            '+${tagCount - 1}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
  }

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
          Row(
            children: tagWidgets,
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

        // 설정 메뉴 + 정렬, 공유, 삭제, 보기모드 토글, 이름변경, 그룹수정 추가
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
                      final count = selectedForDelete.length;  // 삭제할 개수 미리 저장
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

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$count개의 메모장이 휴지통으로 이동했습니다.',
                            style: const TextStyle(color: Colors.white),
                          ),
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
          case 4:
            _showRenameDialog();
            break;
          case 5:
            _showEditGroupDialog();
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
                Text(isGrid ? '목록으로 보기' : '그리드로 보기'),
              ],
            ),
          ),
        ),
        const PopupMenuItem(
          value: 3,
          child: ListTile(
            leading: Icon(Icons.delete),
            title: Text('삭제'),
          ),
        ),
        const PopupMenuItem(
          value: 4,
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('이름변경'),
          ),
        ),
        const PopupMenuItem(
          value: 5,
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('그룹수정'),
          ),
        ),
      ],
    );
  }

void _showSharingSettings() {
  showDialog(
    context: context,
    builder: (context) {
      bool canRead = true;  // 읽기 전용 권한 기본값
      bool canEdit = false; // 편집 권한 기본값

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('공유 설정'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=3'), // 프로필사진 예시
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('user@example.com', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('소유자', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                CheckboxListTile(
                  title: const Text('읽기 전용'),
                  value: canRead,
                  onChanged: (value) {
                    setState(() {
                      canRead = value ?? false;
                      if (!canRead) {
                        canEdit = false;
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('편집 전용'),
                  value: canEdit,
                  onChanged: canRead
                      ? (value) {
                          setState(() {
                            canEdit = value ?? false;
                          });
                        }
                      : null,
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  icon: const Icon(Icons.link),
                  label: const Text('링크 복사'),
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: 'https://example.com/memo_group_link'));
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('링크가 클립보드에 복사되었습니다.')),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  // TODO: 권한 저장 로직 추가 가능
                  Navigator.pop(context);
                },
                child: const Text('확인'),
              ),
            ],
          );
        },
      );
    },
  );
}
  void _showSortOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('정렬 기준 선택'),
          children: [
            RadioListTile<SortOption>(
              title: const Text('최신순'),
              value: SortOption.dateDesc,
              groupValue: sortOption,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    sortOption = value;
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<SortOption>(
              title: const Text('오래된순'),
              value: SortOption.dateAsc,
              groupValue: sortOption,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    sortOption = value;
                  });
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<SortOption>(
              title: const Text('제목순'),
              value: SortOption.titleAsc,
              groupValue: sortOption,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    sortOption = value;
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog() {
    final renameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('이름변경'),
          content: TextField(
            controller: renameController,
            decoration: const InputDecoration(
              hintText: '새 이름을 입력하세요',
            ),
            maxLength: 20,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final newName = renameController.text.trim();
                if (newName.isNotEmpty) {
                  // TODO: 그룹 이름 변경 로직 추가
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('그룹 이름을 "$newName" 으로 변경했습니다.')),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('변경'),
            ),
          ],
        );
      },
    );
  }

  void _showEditGroupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('그룹 수정'),
          content: const Text('그룹 수정 기능은 준비 중입니다.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기')),
          ],
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  final displayList = isSearching ? filteredMemos : dummyMemos;
  final sortedList = _applySorting(displayList);

  return Scaffold(
    appBar: _buildAppBar(),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 예: 검색바, 필터 버튼 등 추가 시 여기 삽입 가능
            Expanded(
              child: sortedList.isEmpty
                  ? Center(
                      child: Text(
                        isSearching
                            ? '검색 결과가 없습니다.'
                            : '저장된 메모가 없습니다.',
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : isGrid
                      ? GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.2,  // 4/3에서 1.2로 줄임 (너무 크면 overflow)
                          ),
                          itemCount: sortedList.length,
                          itemBuilder: (context, index) {
                            return _buildMemoItem(sortedList[index], index);
                          },
                        )
                      : ListView.builder(
                          itemCount: sortedList.length,
                          itemBuilder: (context, index) {
                            return _buildMemoItem(sortedList[index], index);
                          },
                        ),
            ),
          ],
        ),
      ),
    ),
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
  );
}
}
