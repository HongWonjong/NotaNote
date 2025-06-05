import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nota_note/models/group_model.dart';
import 'package:nota_note/pages/main_page/widgets/main_item.dart';
import 'package:nota_note/viewmodels/group_viewmodel.dart';
import 'package:nota_note/widgets/sliding_menu_scaffold.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  final SlidingMenuController _menuController = SlidingMenuController();
  bool _isGroupExpanded = false;
  String? _newGroupName;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 컴포넌트가 마운트되면 그룹 데이터 불러오기
    Future.microtask(() => ref.read(groupViewModelProvider).fetchGroups());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showAddGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('새 그룹 추가'),
        content: TextField(
          controller: _textController,
          decoration: InputDecoration(hintText: '그룹 이름을 입력하세요'),
          onChanged: (value) {
            _newGroupName = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (_newGroupName != null && _newGroupName!.isNotEmpty) {
                ref.read(groupViewModelProvider).createGroup(_newGroupName!);
                _textController.clear();
                Navigator.pop(context);
              }
            },
            child: Text('추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 그룹 데이터 가져오기
    final groupViewModel = ref.watch(groupViewModelProvider);
    final groups = groupViewModel.groups;
    final isLoading = groupViewModel.isLoading;
    final error = groupViewModel.error;

    return SlidingMenuScaffold(
      controller: _menuController,
      menuWidget: _buildMenu(groups),
      contentWidget: _buildContent(groups, isLoading, error),
      animationDuration: const Duration(milliseconds: 250),
      menuBackgroundColor: Colors.white,
    );
  }

  Widget _buildMenu(List<GroupModel> groups) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 47.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/folder_icon.png',
                      color: Color(0xffBFBFBF),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '그룹',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // 그룹 추가 버튼
                    IconButton(
                      onPressed: _showAddGroupDialog,
                      icon: Icon(
                        Icons.add,
                        size: 18,
                        color: Color(0xffBFBFBF),
                      ),
                    ),
                    // 그룹 펼치기/접기 버튼
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isGroupExpanded = !_isGroupExpanded;
                        });
                      },
                      icon: Icon(
                        _isGroupExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_isGroupExpanded) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var group in groups)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: GestureDetector(
                          onTap: () {
                            // 선택한 그룹 정보 표시
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${group.name} 그룹 선택됨 (ID: ${group.id})'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            // 메뉴 닫기
                            _menuController.closeMenu();
                          },
                          child: Text(
                            group.name,
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    if (groups.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          '그룹이 없습니다',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 31),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/trash_icon.png',
                  color: Color(0xffBFBFBF),
                ),
                SizedBox(width: 8),
                Text(
                  '휴지통',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/setting_icon.png',
                  color: Color(0xffBFBFBF),
                ),
                SizedBox(width: 8),
                Text(
                  '설정',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<GroupModel> groups, bool isLoading, String? error) {
    return Scaffold(
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: _menuController.toggleMenu,
              icon: Icon(
                Icons.menu,
                color: Color(0xffB5B5B5),
                size: 24,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.search,
                  color: Color(0xffB1B1B1),
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none,
                  color: Color(0xffB5B5B5),
                  size: 24,
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  if (isLoading)
                    Center(child: CircularProgressIndicator())
                  else if (error != null)
                    Text(
                      error,
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    Text(
                      '총 ${groups.length}개',
                      style: TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? Center(child: CircularProgressIndicator())
                        : groups.isEmpty
                            ? Center(child: Text('그룹이 없습니다'))
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: groups.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: 5),
                                itemBuilder: (context, index) {
                                  return MainItem(
                                    title: groups[index].name,
                                    onTap: () {
                                      // 그룹 ID로 노트 목록을 가져오는 로직
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${groups[index].name} 그룹 선택됨 (ID: ${groups[index].id})'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      // 추후 노트 목록 페이지 구현 후 아래 코드 활성화
                                      /*
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => NoteListPage(
                                            groupId: groups[index].id,
                                            groupName: groups[index].name,
                                          ),
                                        ),
                                      );
                                      */
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGroupDialog,
        backgroundColor: Color(0xFFEFEFEF),
        shape: CircleBorder(),
        elevation: 0,
        child: Icon(
          Icons.add,
          size: 24,
        ),
      ),
    );
  }
}
