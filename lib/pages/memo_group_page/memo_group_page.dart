import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


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

        _buildSettingsMenuInline(),

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

  Widget _buildSettingsMenuInline() {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.menu),
      tooltip: '설정 메뉴',
      onSelected: (value) {
        switch (value) {
          case 1:
            _showSharingSettings();
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
        PopupMenuItem(
          // 보기설정은 value 안줘서 onSelected 호출 안되게 함
          enabled: false,
          child: GestureDetector(
            onTap: () {
              setState(() {
                isGrid = !isGrid;
              });
              // 메뉴 닫기
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

  void _showSharingSettings() {
  String ownerEmail = 'owner@example.com';
  String ownerName = '소유자 이름';
  String selectedPermission = '읽기 전용'; // 초기 권한 값

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('공유'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('이메일')),
                    Expanded(child: Text(ownerEmail, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: Text('소유자')),
                    Expanded(child: Text(ownerName, style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('사용 권한'),
                DropdownButton<String>(
                  value: selectedPermission,
                  items: const [
                    DropdownMenuItem(value: '읽기 전용', child: Text('읽기 전용', style: TextStyle(color: Colors.grey))),
                    DropdownMenuItem(value: '편집 전용', child: Text('편집 전용', style: TextStyle(color: Colors.grey))),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedPermission = value;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('링크 복사'),
                onPressed: () {
                  final link = 'https://example.com/share/link';
                  Clipboard.setData(ClipboardData(text: link));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('공유 링크가 복사되었습니다!')),
                  );
                },
              ),
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
  @override
  Widget build(BuildContext context) {
    final showList = isSearching ? filteredMemos : dummyMemos;

    return Scaffold(
      appBar: _buildAppBar(),
      body: showList.isEmpty
          ? Center(
              child: Text(
                isSearching ? '검색 결과가 없습니다.' : '새로운 메모를 생성해보세요!',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : isGrid
              ? GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: showList.length,
                  itemBuilder: (context, index) {
                    return _buildMemoItem(showList[index], index);
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: showList.length,
                  itemBuilder: (context, index) {
                    return _buildMemoItem(showList[index], index);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 메모 생성 기능 미구현, 임시 메시지 띄우기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('메모 생성 기능은 구현되지 않았습니다.')),
          );
        },
        child: const Icon(Icons.add),
        tooltip: '메모 생성',
      ),
    );
  }
}
