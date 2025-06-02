import 'package:flutter/material.dart';

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
          )
        else ...[
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
          IconButton(
            icon: Icon(isGrid ? Icons.grid_view : Icons.view_list),
            onPressed: () {
              setState(() {
                isGrid = !isGrid;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: Text('공유 기능 준비중', style: TextStyle(fontSize: 18)),
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              switch (value) {
                case '정렬':
                  // 정렬 기능 처리
                  break;
                case '테마 설정':
                  // 테마 설정 처리
                  break;
                case '백업':
                  // 백업 처리
                  break;
                case '휴지통':
                  // 휴지통 처리
                  break;
                case '삭제':
                  setState(() {
                    isDeleteMode = true;
                    selectedForDelete.clear();
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '정렬', child: Text('정렬')),
              const PopupMenuItem(value: '테마 설정', child: Text('테마 설정')),
              const PopupMenuItem(value: '백업', child: Text('백업')),
              const PopupMenuItem(value: '휴지통', child: Text('휴지통')),
              const PopupMenuItem(
                value: '삭제',
                child: Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final currentMemos = isSearching ? filteredMemos : dummyMemos;

    return Scaffold(
      appBar: _buildAppBar(),
      body: currentMemos.isEmpty
          ? Center(
              child: Text(
                isSearching ? '검색 결과가 없습니다.' : '메모가 없습니다. 새 메모를 작성해보세요!',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: isGrid
                  ? GridView.builder(
                      itemCount: currentMemos.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) {
                        return _buildMemoItem(currentMemos[index], index);
                      },
                    )
                  : ListView.builder(
                      itemCount: currentMemos.length,
                      itemBuilder: (context, index) {
                        return _buildMemoItem(currentMemos[index], index);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 새 메모 작성 기능 자리
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('새 메모 작성'),
              content: const Text('새 메모 작성 기능은 아직 구현 중입니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.create),
      ),
    );
  }
}
